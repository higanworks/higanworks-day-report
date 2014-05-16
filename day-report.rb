#!/usr/bin/env ruby

require 'octokit'
require 'kramdown'
require 'pp'

user = ENV['GITHUB_USER']
token = ENV['GITHUB_TOKEN']

client = Octokit::Client.new login: user, oauth_token: token
events = client.user_events user

url_to_detail = {}

events.each do |event|
  #pp event 
  #p ""
  break unless event.created_at.getlocal.to_date == Time.now.to_date
  case event.type
  # commit
  when "PushEvent"
    url_to_detail[event.id] ||= {title: "Push to #{event.repo.name}", 
      commits: event.payload.commits, 
      repo: event.repo, 
      date: event.created_at.getlocal}
  # Wiki
  when "GollumEvent"
    url_to_detail[event.id] ||= {title: "Edit wiki of #{event.repo.name}", 
      pages: event.payload.pages, 
      repo: event.repo, 
      date: event.created_at.getlocal}
  # Issue
  when "IssuesEvent"
    url_to_detail[event.payload.issue.html_url] ||= {
      title: "Issue: '#{event.payload.issue.title}'", 
      acts: [], 
      repo: event.repo, 
      date: event.created_at.getlocal}
    url_to_detail[event.payload.issue.html_url][:acts] << "#{event.payload.action} [#{event.payload.issue.title}](#{event.payload.issue.html_url})"
  # Issue acts
  when "IssueCommentEvent"
    url_to_detail[event.payload.issue.html_url] ||= {
      title: "'#{event.payload.issue.title}'", 
      acts: [], 
      repo: event.repo, 
      date: event.created_at.getlocal}
    url_to_detail[event.payload.issue.html_url][:acts] << "[comment](#{event.payload.comment.html_url})"
  # pull-request
  when "PullRequestEvent"
    url_to_detail[event.payload.pull_request.html_url] ||= {
      title: "Pull request: '#{event.payload.pull_request.title}'", 
      acts: [], 
      repo: event.repo, 
      date: event.created_at.getlocal}
    url_to_detail[event.payload.pull_request.html_url][:acts] << "#{event.payload.action} [#{event.payload.pull_request.title}](#{event.payload.pull_request.html_url})"
  end
end

# create day report
puts Kramdown::Document.new("## #{Time.now.to_date} Day Report of #{user}").to_html
url_to_detail.each do |url, detail|
  puts Kramdown::Document.new("##### #{detail[:date]} : #{detail[:title]}").to_html
  unless detail[:acts].nil?
    detail[:acts].reverse.each do |comment|
      puts Kramdown::Document.new("  * #{comment}").to_html
    end
  end
  unless detail[:commits].nil?
    detail[:commits].reverse.each do |commit|
      puts Kramdown::Document.new("  * commit [#{commit.message.match(/^.*$/)}](http://github.com/#{detail[:repo].name}/commit/#{commit.sha})").to_html
    end
  end
  unless detail[:pages].nil?
    detail[:pages].reverse.each do |page|
      puts Kramdown::Document.new("  * #{page.action} [#{page.page_name} Page](#{page.html_url})").to_html
    end
  end
end
