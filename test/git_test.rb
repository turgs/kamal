require "test_helper"

class GitTest < ActiveSupport::TestCase
  test "uncommitted changes exist" do
    Kamal::Git.expects(:`).with("git status --porcelain").returns("M   file\n")
    Kamal::Git.stubs(:git?).returns(true)
    assert_equal "M   file", Kamal::Git.uncommitted_changes
  end

  test "uncommitted changes do not exist" do
    Kamal::Git.expects(:`).with("git status --porcelain").returns("")
    Kamal::Git.stubs(:git?).returns(true)
    assert_equal "", Kamal::Git.uncommitted_changes
  end

  # Fossil fallbacks

  test "used? is true when git is available" do
    Kamal::Git.stubs(:git?).returns(true)
    Kamal::Git.stubs(:fossil?).returns(false)
    assert Kamal::Git.used?
  end

  test "used? is true when fossil is available" do
    Kamal::Git.stubs(:git?).returns(false)
    Kamal::Git.stubs(:fossil?).returns(true)
    assert Kamal::Git.used?
  end

  test "used? is false when neither is available" do
    Kamal::Git.stubs(:git?).returns(false)
    Kamal::Git.stubs(:fossil?).returns(false)
    assert_not Kamal::Git.used?
  end

  test "revision falls back to fossil" do
    Kamal::Git.stubs(:git?).returns(false)
    Kamal::Git.stubs(:fossil?).returns(true)
    Kamal::Git.expects(:`).with("fossil info 2>/dev/null").returns(
      "checkout:     42d8b46d0a0bdb7fcbd5372e2d5242fe50ab75c6 2026-05-10 08:29:56 UTC\n"
    )
    assert_equal "42d8b46d0a0bdb7fcbd5372e2d5242fe50ab75c6", Kamal::Git.revision
  end

  test "uncommitted changes falls back to fossil" do
    Kamal::Git.stubs(:git?).returns(false)
    Kamal::Git.stubs(:fossil?).returns(true)
    Kamal::Git.expects(:`).with("fossil changes 2>/dev/null").returns("EDITED     config/database.yml\n")
    assert_equal "EDITED     config/database.yml", Kamal::Git.uncommitted_changes
  end

  test "user_name falls back to fossil" do
    Kamal::Git.stubs(:git?).returns(false)
    Kamal::Git.stubs(:fossil?).returns(true)
    Kamal::Git.expects(:`).with("fossil user default 2>/dev/null").returns("tim\n")
    assert_equal "tim", Kamal::Git.user_name
  end

  test "email falls back to fossil" do
    Kamal::Git.stubs(:git?).returns(false)
    Kamal::Git.stubs(:fossil?).returns(true)
    Kamal::Git.expects(:`).with("fossil user default 2>/dev/null").returns("tim\n")
    assert_equal "tim", Kamal::Git.email
  end

  test "root falls back to fossil" do
    Kamal::Git.stubs(:git?).returns(false)
    Kamal::Git.stubs(:fossil?).returns(true)
    Kamal::Git.expects(:`).with("fossil info 2>/dev/null").returns("local-root:   /home/user/myapp/\n")
    assert_equal "/home/user/myapp", Kamal::Git.root
  end

  test "uncommitted_files falls back to fossil" do
    Kamal::Git.stubs(:git?).returns(false)
    Kamal::Git.stubs(:fossil?).returns(true)
    Kamal::Git.expects(:`).with("fossil changes --classify 2>/dev/null").returns("EDITED     config/database.yml\nADDED      app/models/user.rb\n")
    assert_equal [ "config/database.yml", "app/models/user.rb" ], Kamal::Git.uncommitted_files
  end

  test "untracked_files falls back to fossil" do
    Kamal::Git.stubs(:git?).returns(false)
    Kamal::Git.stubs(:fossil?).returns(true)
    Kamal::Git.expects(:`).with("fossil extras 2>/dev/null").returns("tmp/debug.log\n")
    assert_equal [ "tmp/debug.log" ], Kamal::Git.untracked_files
  end

  test "returns safe defaults when no VCS" do
    Kamal::Git.stubs(:git?).returns(false)
    Kamal::Git.stubs(:fossil?).returns(false)
    assert_equal "", Kamal::Git.revision
    assert_equal "", Kamal::Git.user_name
    assert_equal "", Kamal::Git.email
    assert_equal "", Kamal::Git.uncommitted_changes
    assert_equal Dir.pwd, Kamal::Git.root
    assert_equal [], Kamal::Git.uncommitted_files
    assert_equal [], Kamal::Git.untracked_files
  end
end
