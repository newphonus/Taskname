require 'json'
require 'time'

class Task
  attr_accessor :id, :name, :pomodoros, :completed, :created_at
  
  def initialize(id, name)
    @id = id
    @name = name
    @pomodoros = 0
    @completed = false
    @created_at = Time.now.to_s
  end
  
  def to_hash
    {
      'id' => @id,
      'name' => @name,
      'pomodoros' => @pomodoros,
      'completed' => @completed,
      'created_at' => @created_at
    }
  end
  
  def self.from_hash(hash)
    task = new(hash['id'], hash['name'])
    task.pomodoros = hash['pomodoros']
    task.completed = hash['completed']
    task.created_at = hash['created_at']
    task
  end
end

class TimeTracker
  POMODORO_DURATION = 25 * 60
  SHORT_BREAK = 5 * 60
  LONG_BREAK = 15 * 60
  
  def initialize
    @tasks = []
    @current_task = nil
    @filename = 'time_tracker.json'
    load_tasks
  end
  
  def load_tasks
    return unless File.exist?(@filename)
    
    data = JSON.parse(File.read(@filename))
    @tasks = data.map { |h| Task.from_hash(h) }
  rescue
    @tasks = []
  end
  
  def save_tasks
    File.write(@filename, JSON.pretty_generate(@tasks.map(&:to_hash)))
  end
  
  def add_task(name)
    id = @tasks.empty? ? 1 : @tasks.last.id + 1
    task = Task.new(id, name)
    @tasks << task
    save_tasks
    puts "Task added with ID: #{id}"
  end
  
  def delete_task(id)
    @tasks.reject! { |t| t.id == id }
    save_tasks
    puts "Task deleted"
  end
  
  def list_tasks
    if @tasks.empty?
      puts "No tasks"
      return
    end
    
    puts "\n=== Tasks ==="
    @tasks.each do |task|
      status = task.completed ? "[✓]" : "[ ]"
      puts "#{status} #{task.id}. #{task.name} - #{task.pomodoros} pomodoros"
    end
  end
  
  def start_pomodoro(task_id)
    task = @tasks.find { |t| t.id == task_id }
    unless task
      puts "Task not found"
      return
    end
    
    @current_task = task
    puts "\nStarting Pomodoro for: #{task.name}"
    run_timer(POMODORO_DURATION, "Work")
    
    task.pomodoros += 1
    save_tasks
    
    puts "\nPomodoro completed! Total: #{task.pomodoros}"
    
    if task.pomodoros % 4 == 0
      puts "Time for a long break!"
      run_timer(LONG_BREAK, "Long Break")
    else
      puts "Time for a short break!"
      run_timer(SHORT_BREAK, "Short Break")
    end
  end
  
  def run_timer(seconds, label)
    start_time = Time.now
    end_time = start_time + seconds
    
    while Time.now < end_time
      remaining = (end_time - Time.now).to_i
      minutes = remaining / 60
      secs = remaining % 60
      
      print "\r#{label}: #{format('%02d:%02d', minutes, secs)} "
      sleep(1)
    end
    
    puts "\n#{label} finished! 🎉"
    puts "\a"
  end
  
  def complete_task(id)
    task = @tasks.find { |t| t.id == id }
    if task
      task.completed = true
      save_tasks
      puts "Task marked as completed"
    else
      puts "Task not found"
    end
  end
  
  def view_statistics
    total_tasks = @tasks.size
    completed_tasks = @tasks.count(&:completed)
    total_pomodoros = @tasks.sum(&:pomodoros)
    total_minutes = total_pomodoros * 25
    
    puts "\n=== Statistics ==="
    puts "Total Tasks: #{total_tasks}"
    puts "Completed: #{completed_tasks}"
    puts "Pending: #{total_tasks - completed_tasks}"
    puts "Total Pomodoros: #{total_pomodoros}"
    puts "Total Focus Time: #{total_minutes} minutes (#{total_minutes / 60.0} hours)"
  end
  
  def export_report
    report = "Time Tracker Report\n"
    report += "Generated: #{Time.now}\n\n"
    
    @tasks.each do |task|
      report += "#{task.completed ? '[✓]' : '[ ]'} #{task.name}\n"
      report += "  Pomodoros: #{task.pomodoros}\n"
      report += "  Time spent: #{task.pomodoros * 25} minutes\n"
      report += "  Created: #{task.created_at}\n\n"
    end
    
    File.write('time_report.txt', report)
    puts "Report exported to time_report.txt"
  end
end

def main
  tracker = TimeTracker.new
  
  loop do
    puts "\n=== Time Tracker (Pomodoro) ==="
    puts "1. Add Task"
    puts "2. List Tasks"
    puts "3. Start Pomodoro"
    puts "4. Complete Task"
    puts "5. Delete Task"
    puts "6. View Statistics"
    puts "7. Export Report"
    puts "8. Exit"
    
    print "\nEnter choice: "
    choice = gets.chomp
    
    case choice
    when '1'
      print "Task name: "
      name = gets.chomp
      tracker.add_task(name)
      
    when '2'
      tracker.list_tasks
      
    when '3'
      tracker.list_tasks
      print "\nEnter task ID: "
      task_id = gets.chomp.to_i
      tracker.start_pomodoro(task_id)
      
    when '4'
      tracker.list_tasks
      print "\nEnter task ID: "
      task_id = gets.chomp.to_i
      tracker.complete_task(task_id)
      
    when '5'
      tracker.list_tasks
      print "\nEnter task ID: "
      task_id = gets.chomp.to_i
      tracker.delete_task(task_id)
      
    when '6'
      tracker.view_statistics
      
    when '7'
      tracker.export_report
      
    when '8'
      break
      
    else
      puts "Invalid choice"
    end
  end
end

main if __FILE__ == $PROGRAM_NAME
