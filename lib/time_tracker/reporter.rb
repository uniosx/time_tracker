require_relative 'entry_log'

module TimeTracker
  class Reporter

    attr_reader :project, :task, :start_date,
      :end_date

    private :project, :task, :start_date,
      :end_date

    def initialize(args)
      @project = args[:project].to_s if args[:project]
      @task = args[:task].to_s if args[:task]
      @start_date = args[:start_date]
      @start_date = @start_date.to_i if @start_date
      @end_date = args[:end_date]
      @end_date = @end_date.to_i if @end_date
    end

    def hours_tracked
      if project.nil?
        all_hours
      else
        if task.nil?
          project_hours
        else
          project_task_hours
        end
      end
    end

    private

    def all_hours
      rows = EntryLog.where start_time: start_date,
        stop_time: end_date
      build_hours(rows)
    end

    def project_hours
      rows = EntryLog.where project_name: project,
        start_time: start_date, stop_time: end_date
      build_hours(rows)
    end

    def project_task_hours
      rows = EntryLog.where project_name: project,
        task_name: task, start_time: start_date,
        stop_time: end_date
      build_hours(rows)
    end

    def build_hours(rows)
      hours = {}
      hours[:total] = 0
      rows.each do |r|
        project = r['project_name']
        task = r['task_name']
        description = r['description']

        hours[project] = {} unless hours[project]
        hours[project][task] = {} unless hours[project][task]
        hours[project][task][description] = {} unless hours[project][task][description]

        start_time = Time.at(r['start_time']).utc
        stop_time = Time.at(r['stop_time']).utc if r['stop_time']
        if !hours[project][task][description][start_time.to_date]
          hours[project][task][description][start_time.to_date] = 0
        end
        if !hours[project][task][:total]
          hours[project][task][:total] = 0
        end
        interval = diff_hours(start_time, stop_time)
        hours[project][task][description][start_time.to_date] += interval
        hours[project][task][:total] += interval
        hours[:total] += interval
      end
      hours
    end

    def diff_hours(time_one, time_two)
      two = !time_two.nil? ? time_two : end_time(time_one)
      (two - time_one) / 3600.0
    end

    def end_time(time)
      if time.to_date == Date.today
        Time.now
      else
        Time.new(time.year, time.mon, time.day + 1)
      end
    end
  end
end
