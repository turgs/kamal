module Kamal::Git
  extend self

  def used?
    git? || fossil?
  end

  def git?
    system("git rev-parse", err: File::NULL, out: File::NULL)
  end

  def fossil?
    system("fossil status", err: File::NULL, out: File::NULL)
  end

  def user_name
    if git?
      `git config user.name`.strip
    elsif fossil?
      `fossil user default 2>/dev/null`.strip
    else
      ""
    end
  end

  def email
    if git?
      `git config user.email`.strip
    elsif fossil?
      `fossil user default 2>/dev/null`.strip
    else
      ""
    end
  end

  def revision
    if git?
      `git rev-parse HEAD`.strip
    elsif fossil?
      `fossil info 2>/dev/null`[/^checkout:\s+(\S+)/, 1].to_s
    else
      ""
    end
  end

  def uncommitted_changes
    if git?
      `git status --porcelain`.strip
    elsif fossil?
      `fossil changes 2>/dev/null`.strip
    else
      ""
    end
  end

  def root
    if git?
      `git rev-parse --show-toplevel`.strip
    elsif fossil?
      `fossil info 2>/dev/null`[/^local-root:\s+(.+)/, 1].to_s.chomp("/").strip
    else
      Dir.pwd
    end
  end

  # returns an array of relative path names of files with uncommitted changes
  def uncommitted_files
    if git?
      `git ls-files --modified`.lines.map(&:strip)
    elsif fossil?
      `fossil changes --classify 2>/dev/null`.lines.map { |l| l.split(/\s+/, 2).last.strip }
    else
      []
    end
  end

  # returns an array of relative path names of untracked files, including gitignored files
  def untracked_files
    if git?
      `git ls-files --others`.lines.map(&:strip)
    elsif fossil?
      `fossil extras 2>/dev/null`.lines.map(&:strip)
    else
      []
    end
  end
end
