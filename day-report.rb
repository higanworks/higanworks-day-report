#!/usr/bin/ruby

require 'octokit'
require 'kramdown'
require 'pp'

user = ENV['GITHUB_USER']
token = ENV['GITHUB_TOKEN']

client = Octokit::Client.new login: user, oauth_token: token
events = client.user_events user

url_to_detail = {}

events.each do |_|
  #pp _
  #p ""
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
    url_to_detail[_.payload.issue.html_url] ||= {title: "'#{_.payload.issue.title}'", acts: [], repo: _.repo, date: _.created_at.getlocal}
  # Issue acts
  when "IssueCommentEvent"
    url_to_detail[_.payload.issue.html_url] ||= {title: "'#{_.payload.issue.title}'", acts: [], repo: _.repo, date: _.created_at.getlocal}
    url_to_detail[_.payload.issue.html_url][:acts] << "[comment](#{_.payload.comment.html_url})"
  # pull-request
  when "PullRequestEvent"
    url_to_detail[_.payload.pull_request.html_url] ||= {title: "'#{_.payload.pull_request.title}'", acts: [], repo: _.repo, date: _.created_at.getlocal}
    url_to_detail[_.payload.pull_request.html_url][:acts] << "#{_.payload.action} [#{_.payload.pull_request.title}](#{_.payload.pull_request.html_url})"
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
      puts Kramdown::Document.new("  * #{page.action} [#{detail[:repo].name} Wiki #{page.page_name}](#{page.html_url})").to_html
    end
  end
end
