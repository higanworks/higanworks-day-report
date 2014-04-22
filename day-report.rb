#!/usr/bin/ruby

require 'octokit'
require 'kramdown'

user = ENV['GITHUB_USER']
token = ENV['GITHUB_TOKEN']

client = Octokit::Client.new login: user, oauth_token: token
events = client.user_events user

url_to_detail = {}

events.each do |_|
  break unless _.created_at.getlocal.to_date == Time.now.to_date
  case _.type
  # commit
  when "PushEvent"
    url_to_detail[_.id] ||= {title: "Push to #{_.repo.name}", commits: _.payload.commits, repo: _.repo, date: _.created_at.getlocal}
  # Wiki
  when "GollumEvent"
    url_to_detail[_.id] ||= {title: "Edit wiki of #{_.repo.name}", pages: _.payload.pages, repo: _.repo, date: _.created_at.getlocal}
  # Issue
  when "IssuesEvent"
    url_to_detail[_.payload.issue.html_url] ||= {title: "Issue about '#{_.payload.issue.title}'", comments: [], repo: _.repo, date: _.created_at.getlocal}
  # Issue comments
  when "IssueCommentEvent"
    url_to_detail[_.payload.issue.html_url] ||= {title: "Comment about '#{_.payload.issue.title}'", comments: [], repo: _.repo, date: _.created_at.getlocal}
    url_to_detail[_.payload.issue.html_url][:comments] << _.payload.comment.html_url
  # pull-request
  when "PullRequestEvent"
    url_to_detail[_.payload.pull_request.html_url] ||= {title: "Pull-request about '#{_.payload.pull_request.title}'", comments: [], repo: _.repo, date: _.created_at.getlocal}
  end
end

# create day report
puts Kramdown::Document.new("## #{Time.now.to_date} Day Report of #{user}").to_html
url_to_detail.each do |url, detail|
  #p detail
  puts Kramdown::Document.new("##### #{detail[:date]} : #{detail[:title]}").to_html
  unless detail[:comments].nil?
    detail[:comments].reverse.each do |comment|
      puts Kramdown::Document.new("  * #{comment}").to_html
    end
  end
  unless detail[:commits].nil?
    detail[:commits].reverse.each do |commit|
      puts Kramdown::Document.new("  * [#{commit.message.match(/^.*$/)}](http://github.com/#{detail[:repo].name}/commit/#{commit.sha})").to_html
    end
  end
  unless detail[:pages].nil?
    detail[:pages].reverse.each do |page|
      puts Kramdown::Document.new("  * [#{detail[:repo].name} Wiki #{page.page_name}](#{page.html_url}) - #{page.action}").to_html
    end
  end
end
