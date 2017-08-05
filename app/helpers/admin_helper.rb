module AdminHelper

  def log_file_link(log_file)
    link = link_to log_file, admin_log_file_path(log_file: log_file), class: 'btn-default'
    return content_tag(:div, link)
  end

end


