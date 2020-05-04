# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright © 2011-20 Karel Pičman <karel.picman@kontron.com>
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

require File.expand_path('../../test_helper', __FILE__)

class DmsfFolderTest < RedmineDmsf::Test::UnitTest
  fixtures :projects, :users, :email_addresses, :dmsf_folders, :roles, :members, :member_roles,
           :dmsf_folder_permissions
         
  def setup
    @project1 = Project.find 1
    @project1.enable_module! :dmsf
    @project2 = Project.find 2
    @project2.enable_module! :dmsf
    @folder1 = DmsfFolder.find 1
    @folder2 = DmsfFolder.find 2
    @folder4 = DmsfFolder.find 4
    @folder5 = DmsfFolder.find 5
    @folder6 = DmsfFolder.find 6
    @folder7 = DmsfFolder.find 7
    @manager = User.find 2
    @developer = User.find 3
    @manager_role = Role.find 1
    @manager_role.add_permission! :view_dmsf_folders
    developer_role = Role.find 2
    developer_role.add_permission! :view_dmsf_folders
    User.current = @manager
  end

  def test_truth
    assert_kind_of DmsfFolder, @folder1
    assert_kind_of DmsfFolder, @folder1
    assert_kind_of DmsfFolder, @folder4
    assert_kind_of DmsfFolder, @folder5
    assert_kind_of DmsfFolder, @folder6
    assert_kind_of DmsfFolder, @folder7
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
    assert_kind_of User, @manager
    assert_kind_of User, @developer
    assert_kind_of Role, @manager_role
  end

  def test_visiblity
    # The role has got permissions
    User.current = @manager
    assert_equal 7, DmsfFolder.where(project_id: 1).all.size
    assert_equal 5, DmsfFolder.visible.where(project_id: 1).all.size
    # The user has got permissions
    User.current = @developer
    # Hasn't got permissions for @folder7
    @folder7.dmsf_folder_permissions.where(object_type: 'User').delete_all
    assert_equal 4, DmsfFolder.visible.where(project_id: 1).all.size
    # Anonymous user
    User.current = User.anonymous
    @project1.add_default_member User.anonymous
    assert_equal 5, DmsfFolder.visible.where(project_id: 1).all.size
  end

  def test_permissions
    User.current = @developer
    assert DmsfFolder.permissions?(@folder7)
    @folder7.dmsf_folder_permissions.where(object_type: 'User').delete_all
    @folder7.reload
    assert !DmsfFolder.permissions?(@folder7)
  end

  def test_delete
    assert @folder6.delete(false), @folder6.errors.full_messages.to_sentence
    assert @folder6.deleted?, "Folder #{@folder6} hasn't been deleted"
  end

  def test_restore
    assert @folder6.delete(false), @folder6.errors.full_messages.to_sentence
    assert @folder6.deleted?, "Folder #{@folder6} hasn't been deleted"
    assert @folder6.restore, @folder6.errors.full_messages.to_sentence
    assert !@folder6.deleted?, "Folder #{@folder6} hasn't been restored"
  end

  def test_destroy
    @folder6.delete true
    assert_nil DmsfFolder.find_by(id: @folder6.id)
  end

  def test_is_column_on_default
    DmsfFolder::DEFAULT_COLUMNS.each do |column|
      assert DmsfFolder.is_column_on?(column), "The column #{column} is not on?"
    end
  end

  def test_is_column_on_available
    (DmsfFolder::AVAILABLE_COLUMNS - DmsfFolder::DEFAULT_COLUMNS).each do |column|
      assert !DmsfFolder.is_column_on?(column), "The column #{column} is on?"
    end
  end

  def test_get_column_position_default
    # 0 - checkbox
    assert_nil DmsfFolder.get_column_position('checkbox'), "The column 'checkbox' is on?"
    # 1 - id
    assert_nil DmsfFolder.get_column_position('id'), "The column 'id' is on?"
    # 2 - title
    assert_equal DmsfFolder.get_column_position('title'), 1, "The expected position of the 'title' column is 1"
    # 3 - size
    assert_equal DmsfFolder.get_column_position('size'), 2, "The expected position of the 'size' column is 2"
    # 4 - modified
    assert_equal DmsfFolder.get_column_position('modified'), 3, "The expected position of the 'modified' column is 3"
    # 5 - version
    assert_equal DmsfFolder.get_column_position('version'), 4, "The expected position of the 'version' column is 4"
    # 6 - workflow
    assert_equal DmsfFolder.get_column_position('workflow'), 5, "The expected position of the 'workflow' column is 5"
    # 7 - author
    assert_equal DmsfFolder.get_column_position('author'), 6, "The expected position of the 'workflow' column is 6"
    # 8 - custom fields
    assert_nil DmsfFolder.get_column_position('Tag'), "The column 'Tag' is on?"
    # 9 - commands
    assert_equal DmsfFolder.get_column_position('commands'), 7, "The expected position of the 'commands' column is 7"
    # 10 - position
    assert_equal DmsfFolder.get_column_position('position'), 8, "The expected position of the 'position' column is 8"
    # 11 - size
    assert_equal DmsfFolder.get_column_position('size_calculated'), 9,
                 "The expected position of the 'size_calculated' column is 9"
    # 12 - modified
    assert_equal DmsfFolder.get_column_position('modified_calculated'), 10,
                 "The expected position of the 'modified_calculated' column is 10"
    # 13 - version
    assert_equal DmsfFolder.get_column_position('version_calculated'), 11,
                 "The expected position of the 'version_calculated' column is 11"
  end

  def test_directory_tree
    tree = DmsfFolder.directory_tree(@project1)
    assert tree
    # [["Documents", nil],
    #  ["...folder7", 7],
    #  ["...folder1", 1],
    #  ["......folder2", 2] - locked
    #  ["...folder6", 6]]
    assert tree.to_s.include?('...folder1'), "'...folder3' string in the folder tree expected."
    assert !tree.to_s.include?('......folder2'), "'......folder2' string in the folder tree not expected."
  end

  def test_directory_tree_id
    tree = DmsfFolder.directory_tree(@project1.id)
    assert tree
    # [["Documents", nil],
    #  ["...folder7", 7],
    #  ["...folder1", 1],
    #  ["......folder2", 2] - locked
    #  ["...folder6", 6]]
    assert tree.to_s.include?('...folder1'), "'...folder3' string in the folder tree expected."
    assert !tree.to_s.include?('......folder2'), "'......folder2' string in the folder tree not expected."
  end

  def test_folder_tree
    tree = @folder1.folder_tree
    assert tree
    # [["folder1", 1],
    #  ["...folder2", 2] - locked
    assert tree.to_s.include?('folder1'), "'folder1' string in the folder tree expected."
    assert !tree.to_s.include?('...folder2'), "'...folder2' string in the folder tree not expected."
  end

  def test_get_valid_title
    assert_equal '1052-6024 . U_CPLD_5M240Z_SMT_MBGA100_1.8V_-40',
      DmsfFolder::get_valid_title('1052-6024 : U_CPLD_5M240Z_SMT_MBGA100_1.8V_-40...')
    assert_equal 'test', DmsfFolder::get_valid_title("test#{DmsfFolder::INVALID_CHARACTERS}")
  end

  def test_permission_for_role
    checked = @folder7.permission_for_role(@manager_role)
    assert checked
  end

  def test_permissions_users
    users = @folder7.permissions_users
    assert_equal 1,  users.size
  end

  def test_move_to
    assert @folder1.move_to(@project2, nil)
    assert_equal @project2, @folder1.project
    @folder1.dmsf_folders.each do |d|
      assert_equal @project2, d.project
    end
    @folder1.dmsf_files.each do |f|
      assert_equal @project2, f.project
    end
    @folder1.dmsf_links.each do |l|
      assert_equal @project2, l.project
    end
  end

  def test_copy_to
    assert @folder1.copy_to(@project2, nil)
    assert DmsfFolder.find_by(project_id: @project2.id, title: @folder1.title)
  end

end