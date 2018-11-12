require 'test_helper'

class EventTest < ActiveSupport::TestCase

  test "one simple test example" do
    create_opening("2014-08-04 09:30", "2014-08-04 12:30", :weekly_recurring)
    create_appointment("2014-08-11 10:30", "2014-08-11 11:30")

    assert_equal [ {date: Date.parse("2014-08-10"), slots: []},
                   {date: Date.parse("2014-08-11"), slots: ["9:30", "10:00", "11:30", "12:00"]},
                   {date: Date.parse("2014-08-12"), slots: []},
                   {date: Date.parse("2014-08-13"), slots: []},
                   {date: Date.parse("2014-08-14"), slots: []},
                   {date: Date.parse("2014-08-15"), slots: []},
                   {date: Date.parse("2014-08-16"), slots: []} ],
                 Event.availabilities(DateTime.parse("2014-08-10"))
  end

  test "more tests" do
    create_opening("2014-08-04 09:30", "2014-08-04 12:30", :weekly_recurring)
    create_opening("2014-08-14 15:00", "2014-08-14 17:30")
    create_opening("2014-08-18 15:00", "2014-08-18 16:30")
    create_appointment("2014-08-11 10:30", "2014-08-11 11:30")

    # A recurring and a non recurring opening on different days
    assert_equal [ {date: Date.parse("2014-08-10"), slots: []},
                   {date: Date.parse("2014-08-11"), slots: ["9:30", "10:00", "11:30", "12:00"]},
                   {date: Date.parse("2014-08-12"), slots: []},
                   {date: Date.parse("2014-08-13"), slots: []},
                   {date: Date.parse("2014-08-14"), slots: ["15:00", "15:30", "16:00", "16:30", "17:00"]},
                   {date: Date.parse("2014-08-15"), slots: []},
                   {date: Date.parse("2014-08-16"), slots: []} ],
                 Event.availabilities(DateTime.parse("2014-08-10"))

    # A recurring and a non recurring opening on the same day
    assert_equal [ {date: Date.parse("2014-08-15"), slots: []},
                   {date: Date.parse("2014-08-16"), slots: []},
                   {date: Date.parse("2014-08-17"), slots: []},
                   {date: Date.parse("2014-08-18"), slots: ["9:30", "10:00", "10:30", "11:00", "11:30", "12:00", "15:00", "15:30", "16:00"]},
                   {date: Date.parse("2014-08-19"), slots: []},
                   {date: Date.parse("2014-08-20"), slots: []},
                   {date: Date.parse("2014-08-21"), slots: []} ],
                 Event.availabilities(DateTime.parse("2014-08-15"))

    # Before the 1st occurence of the recurring opening
    assert_equal [ {date: Date.parse("2014-07-28"), slots: []},
                   {date: Date.parse("2014-07-29"), slots: []},
                   {date: Date.parse("2014-07-30"), slots: []},
                   {date: Date.parse("2014-07-31"), slots: []},
                   {date: Date.parse("2014-08-01"), slots: []},
                   {date: Date.parse("2014-08-02"), slots: []},
                   {date: Date.parse("2014-08-03"), slots: []} ],
                 Event.availabilities(DateTime.parse("2014-07-28"))
  end

  test "A recurring and a non recurring opening on the same day, with no gap" do
    create_opening("2014-08-04 09:30", "2014-08-04 12:30", :weekly_recurring)
    create_opening("2014-08-25 12:30", "2014-08-25 14:00")
    assert_equal [ {date: Date.parse("2014-08-22"), slots: []},
                   {date: Date.parse("2014-08-23"), slots: []},
                   {date: Date.parse("2014-08-24"), slots: []},
                   {date: Date.parse("2014-08-25"), slots: ["9:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30", "13:00", "13:30"]},
                   {date: Date.parse("2014-08-26"), slots: []},
                   {date: Date.parse("2014-08-27"), slots: []},
                   {date: Date.parse("2014-08-28"), slots: []} ],
                 Event.availabilities(DateTime.parse("2014-08-22"))
  end

  test "Appointments at beggining of opening" do
    create_opening("2014-08-14 15:00", "2014-08-14 17:30")
    create_appointment("2014-08-14 15:00", "2014-08-14 15:30")

    assert_equal [ {date: Date.parse("2014-08-11"), slots: []},
                   {date: Date.parse("2014-08-12"), slots: []},
                   {date: Date.parse("2014-08-13"), slots: []},
                   {date: Date.parse("2014-08-14"), slots: ["15:30", "16:00", "16:30", "17:00"]},
                   {date: Date.parse("2014-08-15"), slots: []},
                   {date: Date.parse("2014-08-16"), slots: []},
                   {date: Date.parse("2014-08-17"), slots: []} ],
                 Event.availabilities(DateTime.parse("2014-08-11"))
  end

  test "Appointments at end of opening" do
    create_opening("2014-08-14 15:00", "2014-08-14 17:30")
    create_appointment("2014-08-14 17:00", "2014-08-14 17:30")

    assert_equal [ {date: Date.parse("2014-08-11"), slots: []},
                   {date: Date.parse("2014-08-12"), slots: []},
                   {date: Date.parse("2014-08-13"), slots: []},
                   {date: Date.parse("2014-08-14"), slots: ["15:00", "15:30", "16:00", "16:30"]},
                   {date: Date.parse("2014-08-15"), slots: []},
                   {date: Date.parse("2014-08-16"), slots: []},
                   {date: Date.parse("2014-08-17"), slots: []} ],
                 Event.availabilities(DateTime.parse("2014-08-11"))
  end

  test "Appointments following each other with no gap" do
    create_opening("2014-08-14 15:00", "2014-08-14 17:30")
    create_appointment("2014-08-14 17:00", "2014-08-14 17:30")
    create_appointment("2014-08-14 16:00", "2014-08-14 17:00")

    assert_equal [ {date: Date.parse("2014-08-11"), slots: []},
                   {date: Date.parse("2014-08-12"), slots: []},
                   {date: Date.parse("2014-08-13"), slots: []},
                   {date: Date.parse("2014-08-14"), slots: ["15:00", "15:30"]},
                   {date: Date.parse("2014-08-15"), slots: []},
                   {date: Date.parse("2014-08-16"), slots: []},
                   {date: Date.parse("2014-08-17"), slots: []} ],
                 Event.availabilities(DateTime.parse("2014-08-11"))
  end

  test "Opening with no availability left" do
    create_opening("2014-08-14 15:00", "2014-08-14 17:30")
    create_appointment("2014-08-14 17:00", "2014-08-14 17:30")
    create_appointment("2014-08-14 16:00", "2014-08-14 17:00")
    create_appointment("2014-08-14 15:00", "2014-08-14 16:00")

    assert_equal [ {date: Date.parse("2014-08-11"), slots: []},
                   {date: Date.parse("2014-08-12"), slots: []},
                   {date: Date.parse("2014-08-13"), slots: []},
                   {date: Date.parse("2014-08-14"), slots: []},
                   {date: Date.parse("2014-08-15"), slots: []},
                   {date: Date.parse("2014-08-16"), slots: []},
                   {date: Date.parse("2014-08-17"), slots: []} ],
                 Event.availabilities(DateTime.parse("2014-08-11"))
  end

  test "Opening at beginning of period" do
    create_opening("2014-08-11 15:00", "2014-08-11 16:00")

    assert_equal [ {date: Date.parse("2014-08-11"), slots: ["15:00", "15:30"]},
                   {date: Date.parse("2014-08-12"), slots: []},
                   {date: Date.parse("2014-08-13"), slots: []},
                   {date: Date.parse("2014-08-14"), slots: []},
                   {date: Date.parse("2014-08-15"), slots: []},
                   {date: Date.parse("2014-08-16"), slots: []},
                   {date: Date.parse("2014-08-17"), slots: []} ],
                 Event.availabilities(DateTime.parse("2014-08-11"))
  end

  test "Opening at end of period" do
    create_opening("2014-08-17 15:00", "2014-08-17 16:00")

    assert_equal [ {date: Date.parse("2014-08-11"), slots: []},
                   {date: Date.parse("2014-08-12"), slots: []},
                   {date: Date.parse("2014-08-13"), slots: []},
                   {date: Date.parse("2014-08-14"), slots: []},
                   {date: Date.parse("2014-08-15"), slots: []},
                   {date: Date.parse("2014-08-16"), slots: []},
                   {date: Date.parse("2014-08-17"), slots: ["15:00", "15:30"]} ],
                 Event.availabilities(DateTime.parse("2014-08-11"))
  end

  test "get_openings_and_appointments" do
    create_opening("2014-08-04 09:30", "2014-08-04 12:30", :weekly_recurring)
    create_opening("2014-08-05 14:00", "2014-08-05 18:00")
    create_appointment("2014-08-11 10:30", "2014-08-11 11:30")

    openings, appointments = Event.get_openings_and_appointments(Date.parse("2014-08-04"))
    assert_equal [{from: DateTime.parse("2014-08-04 09:30"), to: DateTime.parse("2014-08-04 12:30")},
                  {from: DateTime.parse("2014-08-05 14:00"), to: DateTime.parse("2014-08-05 18:00")}], openings
    assert_equal [], appointments

    openings, appointments = Event.get_openings_and_appointments(Date.parse("2014-08-05"))
    assert_equal [{from: DateTime.parse("2014-08-05 14:00"), to: DateTime.parse("2014-08-05 18:00")},
                  {from: DateTime.parse("2014-08-11 09:30"), to: DateTime.parse("2014-08-11 12:30")}], openings
    assert_equal [{from: DateTime.parse("2014-08-11 10:30"), to: DateTime.parse("2014-08-11 11:30")}], appointments
  end

  test "slots" do
    assert_equal [], Event.slots(DateTime.parse("2014-08-09 04:00"),DateTime.parse("2014-08-09 04:00"))
    assert_equal [ {date: Date.parse("2014-08-09"), slot: "4:00"} ],
                 Event.slots(DateTime.parse("2014-08-09 04:00"),DateTime.parse("2014-08-09 04:30"))
    assert_equal [ {date: Date.parse("2014-08-09"), slot: "4:00"},
                   {date: Date.parse("2014-08-09"), slot: "4:30"},
                   {date: Date.parse("2014-08-09"), slot: "5:00"} ],
                 Event.slots(DateTime.parse("2014-08-09 04:00"),DateTime.parse("2014-08-09 05:30"))
  end

  # Create an opening event
  def create_opening(starts_at,ends_at,weekly_recurring = false)
    return create_event('opening', starts_at, ends_at, weekly_recurring)
  end

  # Create an appointment event
  def create_appointment(starts_at,ends_at)
    return create_event('appointment', starts_at, ends_at)
  end

  def create_event(kind,starts_at,ends_at,weekly_recurring = false)
    return Event.create kind: kind, starts_at: DateTime.parse(starts_at), ends_at: DateTime.parse(ends_at), weekly_recurring: (weekly_recurring == :weekly_recurring)
  end
end
