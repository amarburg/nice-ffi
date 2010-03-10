#--
#
# This file is one part of:
#
# Nice-FFI - Convenience layer atop Ruby-FFI
#
# Copyright (c) 2009-2010 John Croisant
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#++


# PathSet is a collection of directory paths and file name templates,
# used to help NiceFFI find library files. It allows per-operating
# system paths and file name templates, using regular expressions to
# match the OS name.
# 
# Each PathSet holds two hashes, @paths and @files.
# 
# * The keys for both @paths and @files are regexps that match
#   FFI::Platform::OS for the operating system(s) that the paths or
#   file templates apply to.
# 
# * The values of @paths are Arrays of one or more strings describing
#   a directory for where a library might be found on this OS. So for
#   example, one pair in @paths might be { /linux|bsd/ =>
#   ["/usr/local/lib/", "/usr/lib/"] }, which means: "For operating
#   systems that match the regular expression /linux|bsd/ (e.g.
#   'linux', 'freebsd', and 'openbsd'), look for libraries first in
#   the directory '/usr/local/lib/', then in '/usr/lib/'."
# 
# * The value of @files are Arrays of one or more strings describing
#   the possible formats of library names for that operating system.
#   These are templates -- they should include string "[NAME]",
#   which will be replaced with the library name. For example,
#   "lib[NAME].so" would become "libSDL_ttf.so" when searching for the
#   "SDL_ttf" library.
# 
# There are several methods to modify @paths and/or @files. See
# #append, #prepend, #replace, #remove, and #delete.
# 
# Once @paths and @files are set up, use #find to look for a file with
# a matching name.
# 
# NiceFFI::PathSet::DEFAULT is a pre-made PathSet with paths and file
# name templates for Linux/BSD, Mac (Darwin), and Windows. It is the
# default PathSet used by NiceFFI::Library.load_library, and you can
# also use it as a base for custom PathSets.
# 
class NiceFFI::PathSet


  def initialize( paths={}, files={} )
    @paths = {}
    @files = {}
    append!( :paths, paths )
    append!( :files, files )
  end
  
  attr_reader :paths, :files

  def dup
    self.class.new( @paths.dup, @files.dup )
  end


  # call-seq:
  #   append( *entries )
  #   append( option, *entries )
  # 
  # Create a copy of this PathSet and append the new paths and/or
  # files. If the copy already has entries for a given regexp, the
  # new entries will be added after the current entries.
  # 
  # option::  You can optionally give either :paths or :files as the
  #           first argument to this method. If :paths, only @paths
  #           will be modified, @files will never be modified. If
  #           :files, only @files will be modified, @paths will never
  #           be modified.
  # 
  # entries:: One or more PathSets, Hashes, Arrays, or Strings,
  #           or any assortment of these types.
  # 
  # * If given a PathSet, its @paths and @files are appended to the
  #   copy's @paths and @files (respectively). If option is :paths,
  #   only @paths is modified. If option is :files, only @files is
  #   modified.
  # 
  # * If given a Hash, it is appended to the copy's @paths, but
  #   @files is not affected. If option is :files, @files is modified
  #   instead of @paths.
  # 
  # * If given an Array (which should contain only Strings), the array
  #   contents are appended to the copy's @paths. If option is
  #   :files, @files is modified instead of @paths.
  # 
  # * If given a String, the string is appended to the copy's
  #   @paths. If option is :files, @files is modified instead of
  #   @paths.
  # 
  # * If given multiple objects, they are handled in order according to
  #   the above rules.
  # 
  # See also #append! for a version of this method which modifies self
  # instead of making a copy.
  # 
  #--
  # Example (out of date):
  # 
  #   ps = PathSet.new( /a/ => ["liba"],
  #                     /b/ => ["libb"] )
  #   
  #   ps.append!( /a/ => ["newliba"],
  #               /c/ => ["libc"] )
  #   
  #   ps.paths
  #   # => { /a/ => ["liba",
  #   #              "newliba"],        # added in back
  #   #      /b/ => ["libb"],           # not affected
  #   #      /c/ => ["libc"] }          # added
  #++
  def append( *entries )
    self.dup.append!( *entries )
  end

  # call-seq:
  #   append!( *entries )
  #   append!( option, *entries )
  # 
  # Like #append, but modifies self instead of making a copy.
  def append!( *entries )
    _modify( *entries ) { |a,b|  a + b }
  end

  alias :+  :append


  # call-seq:
  #   prepend( *entries )
  #   prepend( option, *entries )
  # 
  # Creates a copy of this PathSet and prepends the new paths and/or
  # files. If the copy already has entries for a given regexp, the
  # new entries will be added before the current entries.
  # 
  # option::  You can optionally give either :paths or :files as the
  #           first argument to this method. If :paths, only @paths
  #           will be modified, @files will never be modified. If
  #           :files, only @files will be modified, @paths will never
  #           be modified.
  # 
  # entries:: One or more PathSets, Hashes, Arrays, or Strings,
  #           or any assortment of these types.
  # 
  # * If given a PathSet, its @paths and @files are prepended to this
  #   PathSet's @paths and @files (respectively). If option is :paths,
  #   only @paths is modified. If option is :files, only @files is
  #   modified.
  #
  # * If given a Hash, it is prepended to the copy's @paths, but
  #   @files is not affected. If option is :files, @files is modified
  #   instead of @paths.
  # 
  # * If given an Array (which should contain only Strings), the array
  #   contents are prepended to the copy's @paths. If option is
  #   :files, @files is modified instead of @paths.
  # 
  # * If given a String, the string is prepended to the copy's
  #   @paths. If option is :files, @files is modified instead of
  #   @paths.
  # 
  # * If given multiple objects, they are handled in order according to
  #   the above rules.
  # 
  # See also #prepend! for a version of this method which modifies self
  # instead of making a copy.
  # 
  #--
  # Example (out of date):
  # 
  #   ps = PathSet.new( /a/ => ["liba"],
  #                     /b/ => ["libb"] )
  #   
  #   ps.prepend!( /a/ => ["newliba"],
  #                /c/ => ["libc"] )
  #   
  #   ps.paths
  #   # => { /a/ => ["newliba",         # added in front
  #   #              "liba"],
  #   #      /b/ => ["libb"],           # not affected                
  #   #      /c/ => ["libc"] }          # added
  #++
  def prepend( *entries )
    self.dup.prepend!( *entries )
  end

  # call-seq:
  #   prepend!( *entries )
  #   prepend!( option, *entries )
  # 
  # Like #prepend, but modifies self instead of making a copy.
  def prepend!( *entries )
    _modify( *entries ) { |a,b|  b + a }
  end



  # call-seq:
  #   replace( *entries )
  #   replace( option, *entries )
  # 
  # Creates a copy of this PathSet and overrides existing entries with
  # the new entries. If the copy already has entries for a regexp
  # in the new entries, the old entries will be discarded and the new
  # entries used instead.
  # 
  # option::  You can optionally give either :paths or :files as the
  #           first argument to this method. If :paths, only @paths
  #           will be modified, @files will never be modified. If
  #           :files, only @files will be modified, @paths will never
  #           be modified.
  # 
  # entries:: One or more PathSets, Hashes, Arrays, or Strings,
  #           or any assortment of these types.
  # 
  # * If given a PathSet, the copy's @paths and @files with the
  #   other PathSet's @paths and @files (respectively). Old entries in
  #   the copy are kept if their regexp doesn't appear in the given
  #   PathSet. If option is :paths, only @paths is modified. If option
  #   is :files, only @files is modified.
  # 
  # * If given a Hash, entries in the copy's @paths are replaced
  #   with the new entries, but @files is not affected. Old entries in
  #   the copy are kept if their regexp doesn't appear in the given
  #   PathSet. If option is :files, @files is modified instead of
  #   @paths.
  # 
  # * If given an Array (which should contain only Strings), entries
  #   for every regexp in the copy's @paths are replaced with the
  #   array contents. If option is :files, @files is modified instead
  #   of @paths.
  # 
  # * If given a String, all entries for every regexp in the copy's
  #   @paths are replaced with the string. If option is :files, @files
  #   is modified instead of @paths.
  # 
  # * If given multiple objects, they are handled in order according to
  #   the above rules.
  # 
  # See also #replace! for a version of this method which modifies self
  # instead of making a copy.
  # 
  #--
  # Example (out of date):
  # 
  #   ps = PathSet.new( /a/ => ["liba"],
  #                     /b/ => ["libb"] )
  #   
  #   ps.replace!( /a/ => ["newliba"],
  #                /c/ => ["libc"] )
  #   
  #   ps.paths
  #   # => { /a/ => ["newliba"],        # replaced
  #   #      /b/ => ["libb"],           # not affected
  #   #      /c/ => ["libc"] }          # added
  #++
  def replace( *entries )
    self.dup.replace!( *entries )
  end

  # call-seq:
  #   replace!( *entries )
  #   replace!( option, *entries )
  # 
  # Like #replace, but modifies self instead of making a copy.
  def replace!( *entries )
    _modify( *entries ) { |a,b|  b }
  end



  # call-seq:
  #   remove( *entries )
  #   remove( option, *entries )
  # 
  # Creates a copy of this PathSet and removes the given entries from
  # the copy, if it has them. This only removes the entries that are
  # given, other entries for the same regexp are kept. Regexps with no
  # entries left afterwards are removed from the PathSet.
  # 
  # option::  You can optionally give either :paths or :files as the
  #           first argument to this method. If :paths, only @paths
  #           will be modified, @files will never be modified. If
  #           :files, only @files will be modified, @paths will never
  #           be modified.
  # 
  # entries:: One or more PathSets, Hashes, Arrays, or Strings,
  #           or any assortment of these types.
  # 
  # * If given a PathSet, entries from its @paths and @files are
  #   removed from the copy's @paths and @files (respectively). If
  #   option is :paths, only @paths is modified. If option is :files,
  #   only @files is modified.
  # 
  # * If given a Hash, the given entries are removed from this
  #   PathSet's @paths, but @files is not affected. If option is
  #   :files, @files is modified instead of @paths.
  # 
  # * If given an Array (which should contain only Strings), the array
  #   contents are removed from the entries for every regexp in this
  #   PathSet's @paths. If option is :files, @files is modified
  #   instead of @paths.
  # 
  # * If given a String, the string is removed from the entries for
  #   every regexp in the copy's @paths. If option is :files,
  #   @files is modified instead of @paths.
  # 
  # * If given multiple objects, they are handled in order according to
  #   the above rules.
  # 
  # See also #remove! for a version of this method which modifies self
  # instead of making a copy.
  # 
  #--
  # Example (out of date):
  # 
  #   ps = PathSet.new( /a/ => ["liba", "badliba"],
  #                     /b/ => ["libb"] )
  #   
  #   ps.remove!( /a/ => ["badliba"],
  #               /b/ => ["libb"] )
  #               /c/ => ["libc"] )
  #   
  #   ps.paths
  #   # => { /a/ => ["liba"] }          # removed only "badliba".
  #   #    # /b/ paths were all removed.
  #   #    # /c/ not affected because it had no old paths anyway.
  #++
  def remove( *entries )
    self.dup.remove!( *entries )
  end

  # call-seq:
  #   remove!( *entries )
  #   remove!( option, *entries )
  # 
  # Like #remove, but modifies self instead of making a copy.
  def remove!( *entries )
    _modify( *entries ) { |a,b|  a - b }
  end

  alias :- :remove



  # call-seq:
  #   delete( *regexps )
  #   delete( option, *regexps )
  # 
  # Creates a copy of this PathSet and delete all entries from the
  # copy for the given regexp(s) from @paths and/or @files. Has no
  # effect on entries for regexps that are not given.
  # 
  # option::  You can optionally give either :paths or :files as the
  #           first argument to this method. If :paths, only @paths
  #           will be modified, @files will never be modified. If
  #           :files, only @files will be modified, @paths will never
  #           be modified.
  # 
  # regexps:: One or more Regexps to remove entries for.
  # 
  # See also #delete! for a version of this method which modifies self
  # instead of making a copy.
  # 
  #--
  # Example (out of date):
  # 
  #   ps = PathSet.new( /a/ => ["liba"],
  #                     /b/ => ["libb"] )
  #   
  #   ps.delete!( /b/, /c/ )
  #   
  #   ps.paths
  #   # => { /a/  => ["liba"] }  # not affected
  #   #    # /b/ and all paths removed.
  #   #    # /c/ not affected because it had no paths anyway.
  #++ 
  def delete( *regexps )
    self.dup.delete!( *regexps )
  end

  # call-seq:
  #   delete!( *regexps )
  #   delete!( option, *regexps )
  # 
  # Like #delete, but modifies self instead of making a copy.
  def delete!( *regexps )
    case regexps[0]
    when :paths
      @paths.delete_if { |regexp, paths|  regexps.include? regexp }
    when :files
      @files.delete_if { |regexp, files|  regexps.include? regexp }
    when Symbol
      raise( "Invalid symbol option '#{first.inspect}'. " +
             "Expected :paths or :files." )
    else
      @paths.delete_if { |regexp, paths|  regexps.include? regexp }
      @files.delete_if { |regexp, files|  regexps.include? regexp }
    end
    self
  end



  # Try to find a file based on the paths in this PathSet.
  # 
  # *names:: Strings to try substituting for [NAME] in the paths.
  # 
  # Returns an Array of the paths of matching files, or [] if
  # there were no matches.
  # 
  # Raises LoadError if the current operating system did not match
  # any of the regular expressions in the PathSet.
  # 
  #--
  # Examples (out of date):
  # 
  #   ps = PathSet.new( /linux/   => ["/usr/lib/lib[NAME].so"],
  #                     /windows/ => ["C:\\windows\\system32\\[NAME].dll"] )
  #   
  #   ps.find( "SDL" )
  #   ps.find( "foo", "foo_alt_name" )
  #++
  def find( *names )
    os = FFI::Platform::OS

    # Fetch the paths and files for the matching OSes.
    paths = @paths.collect{ |regexp,ps| regexp =~ os ? ps : [] }.flatten
    files = @files.collect{ |regexp,fs| regexp =~ os ? fs : [] }.flatten

    # Drat, they are using an OS with no matches.
    if paths.empty? and files.empty?
      raise( LoadError, "Your OS (#{os}) is not supported yet.\n" +
             "Please report this and help us support more platforms." )
    end

    results = paths.collect do |path|
      files.collect do |file|
        names.collect do |name|
          # Join path and file, fill in for [NAME], expand, and unglob.
          Dir[ File.expand_path( File.join(path,file).gsub("[NAME]",name) ) ]
        end
      end
    end

    return results.flatten.select{ |r| File.exist? r }
  end


  private


  def _modify( *entries, &block )
    # could be :paths or :files, or perhaps an entry
    part = entries[0]

    case part
    when :paths, :files, :default
      entries = entries[1..-1]
    when Symbol # other symbols are invalid
      raise( "Invalid symbol option '#{first.inspect}'. " +
             "Expected :paths or :files." )
    else
      part = :default
    end

    entries.each do |entry|
      if entry.kind_of? self.class
        if part == :default
          _modify_set( :paths, entry.paths, &block )
          _modify_set( :files, entry.files, &block )
        else
          _modify_set( part, entry.send(part), &block )
        end
      else
        if part == :default
          _modify_set( :paths, entry, &block )
        else
          _modify_set( part, entry, &block )
        end
      end
    end

    return self
  end


  def _modify_set( ours, other, &block )  # :nodoc:
    raise "No block given!" unless block_given?

    ours = case ours
           when :paths;  @paths
           when :files;  @files
           else
             raise( "Invalid symbol option '#{ours.inspect}'. " +
                    "Expected :paths or :files." )
           end

    case other
    when Hash
      # Apply each of the regexps in `other` to the same regexp in `ours`
      other.each do |regexp, paths|
        _apply_modifier( ours, regexp, (ours[regexp] or []), paths, &block )
      end
    when Array
      # Apply `other` to each of the regexps in `ours`
      ours.each { |regexp, paths|
        _apply_modifier( ours, regexp, paths, other, &block )
      }
    when String
      # Apply an Array holding `other` to each of the regexps in `ours`
      ours.each { |regexp, paths|
        _apply_modifier( ours, regexp, paths, [other], &block )
      }
    end
  end


  def _apply_modifier( ours, regexp, a, b, &block ) # :nodoc:
    raise "No block given!" unless block_given?

    result = yield( a, b )

    if result == []
      ours.delete( regexp )
    else
      ours[regexp] = result
    end
  end

end



#--
# NOTE: If you update these defaults, update doc/usage.rdoc too.
#++

paths = {
  /linux|bsd/  => [ "/usr/local/lib/",
                    "/usr/lib/" ],

  /darwin/     => [ "/usr/local/lib/",
                    "/sw/lib/",
                    "/opt/local/lib/",
                    "~/Library/Frameworks/",
                    "/Library/Frameworks/" ],

  /windows/    => [ "C:\\windows\\system32\\",
                    "C:\\windows\\system\\" ]
}

files = {
  /linux|bsd/  => [ "lib[NAME].so*",
                    "lib[NAME]-*.so*" ],

  /darwin/     => [ "lib[NAME].dylib",
                    "lib[NAME]-*.dylib",
                    "[NAME].framework/[NAME]" ],

  /windows/    => [ "[NAME].dll",
                    "[NAME]-*.dll"]
}

# The default paths to look for libraries. See PathSet 
# and NiceFFI::Library.load_library.
# 
NiceFFI::PathSet::DEFAULT = NiceFFI::PathSet.new( paths, files )
