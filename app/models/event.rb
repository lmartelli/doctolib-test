class Event < ApplicationRecord
  def self.availabilities(fromDate)
    nbDays = 7
    toDate = fromDate+(nbDays-1).day
    openings = []
    appointments = []
    availabilities = []
    # Get openings and appointments for the 7 days period
    Event.where("((weekly_recurring = true AND starts_at <= ?) OR starts_at BETWEEN ? AND ?)",toDate,fromDate,toDate).order(:starts_at).each do |event|
      if event.kind == 'opening'
        if event.weekly_recurring then
          delta = (fromDate - event.starts_at.to_date).to_i % nbDays
          d = fromDate
          if delta >0
            d = fromDate + nbDays - delta
          end
          openings << { from: Event.build_datetime(d,event.starts_at), to: Event.build_datetime(d,event.ends_at) }
        else
          openings << { start: event.starts_at, to: event.ends_at }
        end
      else
        appointments << { from: event.starts_at, to: event.ends_at }
      end
    end

    # Compute available slots
    openings.sort_by! { |times| times[0] }
    slots = []
    openings.each do |opening|
      from,to = opening[:from], opening[:to]
      while not appointments.empty? and to > appointments[0][:from]
        slots += slots(from,appointments[0][:from])
        from = appointments[0][:to]
        appointments.shift
      end
      slots += slots(from,to)
    end

    # Group available slots by date
    slot = slots.shift
    nbDays.times do |i|
      d = (fromDate + i.days).to_date
      s = []
      while slot != nil and slot[:date] == d
        s << slot[:slot]
        slot = slots.shift        
      end
      availabilities << { date: d, slots: s }
    end
    
    return availabilities
  end

  # Builds a DateTime from a Date and the time of a DateTime or Time
  def self.build_datetime(date,time)
    return DateTime.new(date.year,date.month,date.day,time.hour,time.to_datetime.minute)
  end

  
  def self.slots(from,to)
    d = from.to_date
    slots = []
    while from < to
      slots << { date: d, slot: from.strftime("%-k:%M") }
      from += 30.minutes
    end
    return slots
  end
end
