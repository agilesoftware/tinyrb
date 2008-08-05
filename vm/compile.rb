# Compile a Ruby script to an embedable C header file containing an array
# of instruction sequences generated by YARV.
# Usage:
# 
#  ruby19 compile.rb boot boot.rb > boot.h
#
# Then include in your C code:
#
#  #include "boot.h"

raise "Ruby 1.9 required" unless RUBY_VERSION =~ /1\.9/

# Stolen from HotRuby: http://hotruby.accelart.jp/js/HotRuby.js
OUTPUT_COMPILE_OPTION = {
  :peephole_optimization    => true,
  :inline_const_cache       => false,
  :specialized_instruction  => false,
  :operands_unification     => false,
  :instructions_unification => false,
  :stack_caching            => false,
}

name, file = ARGV

iseq = VM::InstructionSequence.compile_file(file, OUTPUT_COMPILE_OPTION)

puts '#ifndef _BOOT_H_'
puts '#define _BOOT_H_'
puts
puts '#include "tinyrb.h"'
puts
puts "tr_op tr_#{name}_insts[] = {"

# TODO clean this crap!
iseq.to_a.last.each do |inst|
  next if inst.is_a?(Fixnum)
  
  if inst.is_a?(Symbol) # label
    puts %Q{  { LABEL, { "#{inst}", 0, 0, 0, 0 } }, }
    next
  end
  
  opcode   = inst[0].to_s.upcase
  operands = [].fill(0, 0, 5)
  
  Array(inst[1]).each_with_index do |op, i|
    case op
    when Symbol
      operands[i] = %Q{(OBJ) "#{op}"}
    when NilClass
    else
      operands[i] = "(OBJ) #{op.inspect}"
    end
  end
  puts "  { #{opcode}, { #{operands.join(', ')} } },"
end

puts '};'
puts '#endif /* _BOOT_H_ */'