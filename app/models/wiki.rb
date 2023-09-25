# frozen_string_literal: true

# Redmine - project management software
# Copyright (C) 2006-2023  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class Wiki < ActiveRecord::Base
  include Redmine::SafeAttributes
  belongs_to :project
  # pages 검색 쿼리 수정
#  has_many :pages, lambda {order(Arel.sql('LOWER(title)').asc)}, :class_name => 'WikiPage', :dependent => :destroy
  has_many :pages, lambda {order(Arel.sql('id').asc)}, :class_name => 'WikiPage', :dependent => :destroy
  has_many :redirects, :class_name => 'WikiRedirect'

  acts_as_watchable
#  start_page 변수검사 제거
#  validates_presence_of :start_page
#  validates_format_of :start_page, :with => /\A[^,\.\/\?\;\|\:]*\z/
#  validates_length_of :start_page, maximum: 255

  before_destroy :delete_redirects

  safe_attributes 'start_page'

  def visible?(user=User.current)
    !user.nil? && user.allowed_to?(:view_wiki_pages, project)
  end

  # Returns the wiki page that acts as the sidebar content
  # or nil if no such page exists
  def sidebar
    @sidebar ||= find_page('Sidebar', :with_redirect => false)
  end

  # find the page with the given title
  # if page doesn't exist, return a new page
  # Title 미사용으로 id로 변경
#  def find_or_new_page(title)
#    title = start_page if title.blank?
  def find_or_new_page(id)
    id = start_page if id.blank?
    # 신규 페이지 생성 삭제 / 기본 페이지로 이동 설정
#    find_page(title) || WikiPage.new(:wiki => self, :title => Wiki.titleize(title))
    find_page(id)
  end

  # find the page with the given title
  def find_page(id, options = {})
    @page_found_with_redirect = false
    # title 미사용 id 사용
#    title = start_page if title.blank?
    id = start_page if id.blank?
    # titleize 제거
#    title = Wiki.titleize(title)
#    page = pages.find_by("LOWER(title) = LOWER(?)", title)
    page = pages.find_by("id = ?", id)
    # Redirect 제거
#    if page.nil? && options[:with_redirect] != false
#      # search for a redirect
#      redirect = redirects.where("LOWER(title) = LOWER(?)", title).first
#      if redirect
#        page = redirect.target_page
#        @page_found_with_redirect = true
#      end
#    end
#    if page.nil?
#      page = pages.find_by("id = ?", start_page)
#    end
    page
  end

  # Returns true if the last page was found with a redirect
  def page_found_with_redirect?
    @page_found_with_redirect
  end

  # Deletes all redirects from/to the wiki
  def delete_redirects
    WikiRedirect.where(:wiki_id => id).delete_all
    WikiRedirect.where(:redirects_to_wiki_id => id).delete_all
  end

  # Finds a page by title
  # The given string can be of one of the forms: "title" or "project:title"
  # Examples:
  #   Wiki.find_page("bar", project => foo)
  #   Wiki.find_page("foo:bar")
  # Title 미사용
#  def self.find_page(title, options = {})
  def self.find_page(id, options = {})
    project = options[:project]
#    if title.to_s =~ %r{^([^\:]+)\:(.*)$}
#      project_identifier, title = $1, $2
    if id.to_s =~ %r{^([^\:]+)\:(.*)$}
      project_identifier, id = $1, $2
      project = Project.find_by_identifier(project_identifier) || Project.find_by_name(project_identifier)
    end
    if project && project.wiki
#      page = project.wiki.find_page(title)
      page = project.wiki.find_page(id)
      if page && page.content
        page
      end
    end
  end

  # 미사용
  # turn a string into a valid page title
  def self.titleize(title)
    # replace spaces with _ and remove unwanted caracters
    title = title.gsub(/\s+/, '_').delete(',./?;|:') if title
    # upcase the first letter
    title = (title.slice(0..0).upcase + (title.slice(1..-1) || '')) if title
    title
  end
end
