#!/usr/bin/ruby

require 'octokit'

user = "user"
token = "token"

client = Octokit::Client.new login: user, oauth_token: token
events = client.user_events user

url_to_detail = {}

events.each do |_|
  break unless _.created_at.getlocal.to_date == Time.now.to_date
  case _.type
  # commit
  when "PushEvent"
    url_to_detail[_.id] ||= {title: "push to #{_.repo.name}", commits: _.payload.commits, repo: _.repo, date: _.created_at.getlocal}
  # Wiki
  when "GollumEvent"
    url_to_detail[_.id] ||= {title: "edit wiki of #{_.repo.name}", pages: _.payload.pages, repo: _.repo, date: _.created_at.getlocal}
  # Issue
  when "IssuesEvent"
    url_to_detail[_.payload.issue.html_url] ||= {title: _.payload.issue.title, comments: [], repo: _.repo, date: _.created_at.getlocal}
  # Issue comments
  when "IssueCommentEvent"
    url_to_detail[_.payload.issue.html_url] ||= {title: _.payload.issue.title, comments: [], repo: _.repo, date: _.created_at.getlocal}
    url_to_detail[_.payload.issue.html_url][:comments] << _.payload.comment.html_url
  # pull-request
  when "PullRequestEvent"
    url_to_detail[_.payload.pull_request.html_url] ||= {title: _.payload.pull_request.title, comments: [], repo: _.repo, date: _.created_at.getlocal}
  end
end

# create day report
puts "## #{Time.now.to_date} Day Report of #{user}"
url_to_detail.each do |url, detail|
  puts "##### #{detail[:date]} : #{detail[:title]})"
  unless detail[:comments].nil?
    detail[:comments].reverse.each do |comment|
      puts "  * #{comment}"
    end
  end
  unless detail[:commits].nil?
    detail[:commits].reverse.each do |commit|
      puts "  * [#{commit.message}](http://github.com/#{detail[:repo].name}/commit/#{commit.sha})"
    end
  end
  unless detail[:pages].nil?
    detail[:pages].reverse.each do |page|
      puts "  * [#{detail[:repo].name} Wiki #{page.page_name}](#{page.html_url}) - #{page.action}"
    end
  end
end
