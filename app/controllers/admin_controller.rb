class AdminController < ApplicationController

  before_action :authenticate_user!

  def system
    return redirect_to root_path unless current_user.admin?
  end

  def logs
    return redirect_to root_path unless current_user.valet_admin?

    @log_dir = APP_CONFIG['log_directory']
    # sort newest first
    @log_files = Dir["#{@log_dir}/*.log"].sort.reverse

    # # download a specific log file
    # if log_file = params[:log_file]
    #   return redirect_to root_path unless @log_files.include?(log_file)
    #   send_file(log_file)
    #   return
    # end
    # 
  end

  def log_file
    return redirect_to root_path unless current_user.valet_admin?

    log_file = params[:log_file]
    return redirect_to root_path unless log_file

    # Validate the input arg
    @log_dir = APP_CONFIG['log_directory']
    @log_files = Dir["#{@log_dir}/*.log"]
    return redirect_to root_path unless @log_files.include?(log_file)

    @headers = []
    @rows = []
    File.foreach(log_file) do |line|
      row = []

      line.split('|').each do |field|
        # gather headers only when working on first row
        header = '' if @rows.size == 0
        if match = field.match(/(\w+)=(.*)/)
          # If this field is key=value
          header, value = match.captures
        else
          # else if this field is "value" (no key)
          header = ''
          value = field
        end
        row.push(value)
        # gather headers only when working on first row
        @headers.push(header) if @rows.size == 0
      end
      
      @rows.push(row)
    end

  end

end
