# Copyright (C) 2009 Mobile Sorcery AB
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License, version 2, as published by
# the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the Free
# Software Foundation, 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.

# This is the base file for the Work system.
# Work is a library designed to help generate new files from existing source files.
# In other words, a build system.
# Work shares some similarities with <em>make</em> and <em>rake</em>,
# especially in its base structure, but have many additions.
# It's designed to be fast; minimizing the number of processes started and
# the number of file system accesses.
#
# Author:: Fredrik Eldh (mailto:fredrik.eldh@mobilesorcery.com)
# Copyright:: Copyright (c) 2009 Mobile Sorcery AB
# License:: GNU GPL, version 2

require "#{File.dirname(__FILE__)}/defaults.rb"
require "#{File.dirname(__FILE__)}/targets.rb"
require 'fileutils'
require 'singleton'

# This is the base class for the Work system.
class TaskBase
	# EarlyTime is a fake timestamp that occurs _before_ any other time value.
	# Its instance is called EARLY.
	class EarlyTime
		include Comparable
		include Singleton
		
		def <=>(other)
			-1
		end
		
		def to_s
			"<EARLY TIME>"
		end
	end
	EARLY = EarlyTime.instance
	
	# LateTime is a fake timestamp that occurs _after_ any other time value.
	# Its instance is called LATE.
	class LateTime
		include Comparable
		include Singleton
		
		def <=>(other)
			1
		end
		
		def to_s
			"<LATE TIME>"
		end
	end
	LATE = LateTime.instance
	
	def initialize()
		@prerequisites = []
	end
	
	# An array of TaskBase objects that must be invoked before this object can be executed.
	attr_accessor(:prerequisites)
	
	# Writes a readable representation of this TaskBase and its prerequisites to stdout.
	def dump(level)
		@prerequisites.each do |p| p.dump(level+1) end
	end
end

# A Work represents the end result of a build process.
# This is often an executable file or a library.
# A Work is not quite a Task. It has prerequisites and responds to invoke, but that's it.
# Work also cooperates with the Target system.
# Work is abstract; subclasses must define the setup and execute_clean methods.
class Work < TaskBase
	def initialize
		@prerequisites = nil
	end
	
	def invoke
		#puts "Work.invoke: #{@NAME.inspect}"
		
		if(@prerequisites == nil) then
			setup
			if(@prerequisites == nil)
				error "setup failed"
			end
		end
		
		# If you invoke a work without setting up any targets,
		# we will check for the "clean" goal here.
		if(Targets.size == 0)
			Targets.setup
			if(Targets.goals == [:clean])
				self.execute_clean
				return
			end
		end
		
		@prerequisites.each do |p| p.invoke end
	end
	
	# Invoke the workfile of another directory, as if it would have been called from the command line.
	def Work.invoke_subdir(dir, *args)
		puts File.expand_path(dir) + " " + args.inspect
		fn = dir + "/workfile.rb"
		if(!File.exists?(fn))
			error "No workfile found in #{dir}"
		end
		
		if(defined?(Targets))
			Targets.reset(args)
		end
		
		oldDir = Dir.getwd
		Dir.chdir(dir)
		load(File.expand_path('workfile.rb'), true)
		Dir.chdir(oldDir)
	end
	
	def Work.invoke_subdirs(dirs, *args)
		dirs.each do |dir| Work.invoke_subdir(dir, *args) end
	end
end

# Represents an ordinary build process, where new files are created in a designated directory.
# Implements setup, but requires subclasses to define setup2.
# Includes a set of default member variables used by the different subclasses.
# To override the default value of such a variable, it must be set before setup is called.
class BuildWork < Work
	include Defaults
	def initialize
		Targets.setup
		super
	end
	
	def setup
		#puts "BuildWork.setup: #{@NAME.inspect}"
		set_defaults
		@prerequisites = [DirTask.new(self, @BUILDDIR)]
		setup2
		#dump(0)
	end
	
	# Removes all files generated by this Work.
	def execute_clean
		#puts "execute_clean in #{self.inspect}"
		verbose_rm_rf(@TARGET)
		verbose_rm_rf(@BUILDDIR)
	end
end

# This is the base class for general-purpose tasks.
# @work is the Work to which this Task is attached.
class Task < TaskBase
	def initialize(work)
		super()
		@work = work
	end
	
	# Invokes this Task. First invokes all prerequisites, then
	# calls <tt>execute</tt> to perform whatever actions are necessary.
	# <tt>execute</tt> is not implemented in the base classes; one must create subclasses
	# and implement it.
	def invoke
		#puts "invoke: #{self}"
		@prerequisites.each do |p| p.invoke end
		if(self.needed?) then
			puts "Execute: #{self}"
			self.execute
		end
	end
	
	# A Task's timestamp is used for comparison with other Tasks to determine
	# if a target is older than a source and thus needs to be remade.
	# This default implementation returns EARLY.
	def timestamp
		EARLY
	end
	
	# Returns true if this Task should be executed, false otherwise.
	def needed?(log = true)
		true
	end
end

# A Task representing a file.
# @NAME is the name of the file.
class FileTask < Task
	def initialize(work, name)
		super(work)
		@NAME = name.to_s
	end
	
	def to_str
		@NAME
	end
	
	def to_s
		@NAME
	end
	
	def execute
		error "Don't know how to build #{@NAME}"
	end
	
	# Is this FileTask needed?  Yes if it doesn't exist, or if its time stamp
	# is out of date.
	# Prints the reason the task is needed, unless <tt>log</tt> is false.
	def needed?(log = true)
		if(!File.exist?(@NAME))
			puts "Because file does not exist:" if(log)
			return true
		end
		return true if out_of_date?(timestamp, log)
		return false
	end
	
	# Time stamp for file task. If the file exists, this is the file's modification time,
	# as reported by the filesystem.
	def timestamp
		if File.exist?(@NAME)
			File.mtime(@NAME)
		else
			LATE
		end
	end
	
	# Are there any prerequisites with a later time than the given time stamp?
	def out_of_date?(stamp, log=true)
		@prerequisites.each do |n|
			if(n.timestamp > stamp)
				puts "Because prerequisite '#{n}'(#{n.class}) is newer:" if(log)
				return true
			end
		end
		return false
	end
	
	def dump(level)
		puts (" " * level) + @NAME
		super
	end
end

# A Task for creating a directory, recursively.
# For example, if you want to create 'foo/bar', you need not create two DirTasks. One will suffice.
class DirTask < FileTask
	def execute
		FileUtils.mkdir_p @NAME
	end
	def timestamp
		if File.exist?(@NAME)
			EARLY
		else
			LATE
		end
	end
end

# A Task for copying a file.
class CopyFileTask < FileTask
	# name is a String, the destination filename.
	# src is a FileTask, the source file.
	# preq is an Array of Tasks, extra prerequisites.
	def initialize(work, name, src, preq = [])
		super(work, name)
		@src = src
		@prerequisites = [src] + preq
	end
	def execute
		puts "cp #{@NAME} #{@src}"
		FileUtils.copy_file(@src, @NAME, true)
	end
end
