class Event < ApplicationRecord
  PeriodLength = 7 # Can be less, but more would require to change the algorithm
  SlotDuration = 30.minutes

  # Returns availabilities from fromDate for 7 days
  # Preconditions:
  #    - openings should start and end on the same day
  #    - openings should not overlap
  #    - all appointments should be in an opening
  #    - minutes in hour are a multiple of slot duration (either "00" or "30" for 30 minutes slots)
  def self.availabilities(fromDate)
    openings, appointments = get_openings_and_appointments(fromDate)

    # Compute available slots
    slots = []
    openings.each do |opening|
      from,to = opening[:from], opening[:to]
      while not appointments.empty? and appointments[0][:from] < to
        slots += slots(from,appointments[0][:from])
        from = appointments[0][:to]
        appointments.shift
      end
      slots += slots(from,to)
    end

    # Group available slots by date
    availabilities = []
    slot = slots.shift
    PeriodLength.times do |i|
      d = (fromDate + i.days).to_date
      s = []
      while slot != nil and slot[:date] == d
        s << slot[:time]
        slot = slots.shift        
      end
      availabilities << { date: d, slots: s }
    end
    
    return availabilities
  end

  # Get openings and appointments for the period, as a map having :from and to: keys, sorted by :from
  def self.get_openings_and_appointments(fromDate)
    openings = []
    appointments = []
    Event
      .where("(weekly_recurring = true AND starts_at <= :from) OR (starts_at >= :from AND starts_at < :to)",{from: fromDate,to: fromDate+(PeriodLength).day})
      .order(:starts_at)
      .each do |event|
      if event.kind == 'opening'
        if event.weekly_recurring then
          d = fromDate + ( (event.starts_at.to_date - fromDate).to_i % PeriodLength )
          openings << { from: Event.build_datetime(d,event.starts_at), to: Event.build_datetime(d,event.ends_at) }
        else
          openings << { from: event.starts_at, to: event.ends_at }
        end
      else
        appointments << { from: event.starts_at, to: event.ends_at }
      end
    end
    # Sort again that recurring openings are at the right place
    openings.sort_by! { |opening| opening[:from] }
    return openings,appointments
  end

  # Builds a DateTime from a Date and the time of a DateTime or Time
  def self.build_datetime(date,time)
    return DateTime.new(date.year,date.month,date.day,time.hour,time.to_datetime.minute)
  end

  # Gets 30 minutes time slots
  # @return [ { date: ..., time: ...}, ... ]
  def self.slots(from,to)
    d = from.to_date
    slots = []
    while from < to
      slots << { date: d, time: from.strftime("%-k:%M") }
      from += SlotDuration
    end
    return slots
  end
end
