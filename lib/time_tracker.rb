require 'optparse'
require_relative 'time_tracker/sync'
require_relative 'time_tracker/tracker'
require_relative 'time_tracker/reporter'

module TimeTracker
  class CLI
    attr_reader :sync

    def initialize
      @sync = Sync.new
    end

    def process
      command = ARGV.shift
      case command
      when 'track'
        track_time
      when 'hours'
        print_hours
      when 'sync'
        sync.run EntryLog.where 'entry_log_id is null'
      else
        print_options
      end
    end

    private

    def track_time
      project, task, description = project_args(ARGV.shift)
      entry_log = Tracker.new(project: project,
        task: task, description: description).track
      if entry_log.ended_at.nil?
        puts "on the clock"
      else
        puts "off the clock"
        sync.run EntryLog.where 'entry_log_id is null'
      end
    end

    def project_args(arg)
      project, task, description = arg.split ':'
      fail 'Project' unless !project.nil? && !project.empty?
      [project, task, description]
    end

    def print_hours
      verbose = false
      rounded = false
      while arg = ARGV.shift
        case arg
        when /-r|--rounded/
          rounded = true
        when /-v|--verbose/
          verbose = true
        when /-s|--start/
          start_date = get_start_date
        when /-e|--end/
          end_date = get_end_date
        else
          project, task, description = project_args(arg)
        end
      end
      project_hours = Reporter.new(
        project: project,
        task: task,
        description: description,
        start_date: start_date,
        end_date: end_date
      ).hours_tracked
      print_projects(project_hours, verbose, rounded)
    end

    def print_options
      puts "\n\tUsage: time_tracker <command> [project]:[task]:[description] [OPTIONS]\n\n\
        Commands\n\
            track        track time for project tasks\n\
            hours        print hours tracked for project tasks in date range\n\

        Options\n\
            -s, --start <YYYY-MM-DD>    used with hours command
            -e, --end <YYYY-MM-DD>      used with hours command
            -v, --verbose               used with hours command
            -r, --rounded               used with hours command\n\n\
        Examples\n\
            time_tracker track company:api\n\
            time_tracker track company:api\n\
            time_tracker track company:frontend\n\
            time_tracker track company:frontend\n\
            time_tracker track company:frontend:'Update hover css'\n\
            time_tracker hours company:api\n\
            time_tracker hours company:frontend\n\
            time_tracker hours company -s 2014-1-1\n\
            time_tracker hours company -s 2014-1-1 -e 2014-2-1\n\
            time_tracker hours -s 2014-1-1 -e 2014-2-1\n\n"
    end

    def get_start_date
      start_date = ARGV.shift
      abort 'Include start date with -s switch' if start_date.nil?
      start_date = start_date.split("-")
      Time.new(start_date[0], start_date[1], start_date[2])
    end

    def get_end_date
      end_date = ARGV.shift
      abort 'Include end date with -e switch' if end_date.nil?
      end_date = end_date.split("-")
      Time.new(end_date[0], end_date[1], end_date[2])
    end

    def print_projects(hours, verbose, rounded)
      if rounded
        if verbose
          print_project_hours(hours, true)
        else
          puts rounded_project_hours(hours)
        end
      else
        if verbose
          print_project_hours(hours)
        else
          puts hours[:total].round(2)
        end
      end
    end

    def rounded_project_hours(hours)
      hours.delete :total
      hours.inject(0) do |sum, project_task|
        project_task[1].each do |prj, task|
          task.delete :total
          task.each do |t, entries|
            entries.each do |date, h|
              sum += nearest_quarter(h)
            end
          end
        end
        sum
      end
    end

    def nearest_quarter(hours)
      (hours * 4).ceil / 4.0
    end

    def print_project_hours(hours, rounded = false)
      hours.delete :total
      project_hours = 0
      hours.each do |project, tasks|
        project_hours = print_tasks(project, tasks, rounded)
        if project_hours > 0
          puts "  total:                    #{project_hours.round(2)} hours\n\n"
        end
      end
      puts "All Projects and tasks\ntotal: #{project_hours.round(2)}"
    end

    def print_tasks(project, tasks, rounded)
      project_hours = 0
      first = true
      tasks.each do |task, description|
        project_hours += print_task(project, task, description, first, rounded)
        project_hours = nearest_quarter(project_hours) if rounded
        first = false
      end
      project_hours
    end

    def print_task(project, task, description, first, rounded)
      total = 0
      description.delete :total
      if description.size > 0
        if first
          puts "Project: #{project}"
        end
        puts "  Task: #{task}"
        description.each do |title, date|
          puts "    Description: #{title}"
          date.each do |day, hours|
            h = rounded ? nearest_quarter(hours) : hours.round(2)
            total += h
            puts "      #{day}:           #{h} hours"
          end
        end
        puts "      total:                #{total.round(2)} hours"
        puts
      end
      total
    end
  end
end
