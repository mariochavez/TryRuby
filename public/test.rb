require 'pp'
require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'

load 'tryruby_runner.rb'

class TryRubyTest < Test::Unit::TestCase

  def tryruby_session(session = TryRubyTestSession.new, &block)
    input_o = Hash.new
    input_o[:session] = session
    input_o[:test] = self
    def input_o.input(line, params = {})
      params[:output] ||= ""
      params[:result] ||= nil
      params[:error] ||= nil
      
      o = Object.new
      session = self[:session]
      result = o.instance_eval do
        res = run_script(session, line)
      end

      begin
        tester = self[:test]
        if params[:error] then
          tester.assert_equal(:error, result.type, 
                              "Testing if line `#{line}` resulted in an error")
          tester.assert_equal(params[:error], result.error.class,
                              "Testing if line `#{line}` result in the right error")
          return
        end
        if params[:line_continuation]
          tester.assert_equal(:line_continuation, result.type,
                              "Testing if line `#{line}' resulted in a line continuation")
          if params[:line_continuation] != true then
            tester.assert_equal(result.indent_level, params[:line_continuation],
                                "Testing if line `#{line}' triggered enough autoindent")
          end
          return
        end
        tester.assert_nil(result.error,
                          "Testing line `#{line}' to ensure there was no error")
        tester.assert_equal(params[:result],
                            result.result,
                            "Testing line `#{line}' for correct result")

        tester.assert_equal(params[:output],
                            result.output,
                            "Testing line `#{line}' for correct output")
      rescue Test::Unit::AssertionFailedError => e
        new_bt = Test::Unit::Util::BacktraceFilter.filter_backtrace(e.backtrace)[1..1]
        e.set_backtrace(new_bt)
        raise e
        
      end


    end
    input_o.instance_eval(&block)
    
  end

  def test_lesson1
    tryruby_session do
      input '2 + 6', :result => 8
      input '"Jimmy"', :result => "Jimmy"
      input '"Jimmy".reverse', :result => "ymmiJ"
      input '"Jimmy".length', :result => 5
      input '"Jimmy" * 5', :result => "JimmyJimmyJimmyJimmyJimmy"
    end
  end

  def test_lesson2
    tryruby_session do
      input '40.reverse', :error => NoMethodError
      input '40.to_s.reverse', result: "04"
      input '[]', result: []
      input '[12,47,35]', result: [12,47,35]
      input '[12,47,35].max', result: 47
      input 'ticket = [12,47,35]', result: [12,47,35]
      input 'ticket', result: [12,47,35]
      input 'ticket.sort!', result: [12,35,47]
    end
  end

  def test_lesson3
    poem = <<-EOF
My toast has flown from my hand
And my toast has gone to the
moon.
But when I saw it on television,
Planting our flag on Halley's
comet,
More still did I want to eat it.
EOF
    
    tryruby_session do
      input 'print poem', output: poem
      input "poem['toast'] = 'honeydew'", result: "honeydew"
      input 'print poem', output: (poem['toast'] = 'honeydew'; poem)
      input 'poem.reverse', result: poem.reverse
      input 'poem.lines.to_a.reverse', result: poem.lines.to_a.reverse
      input 'print poem.lines.to_a.reverse.join', output: poem.lines.to_a.reverse.join
      end
  end

  def test_lesson4
    tryruby_session do
      input 'books = {}', result: {}
      input 'books["Gravity\'s Rainbow"] = :splendid', result: :splendid
      input 'books["a"] = :mediocre', result: :mediocre
      input 'books["b"] = :mediocre', result: :mediocre
      input 'books["c"] = :mediocre', result: :mediocre
      input 'books.length', result: 4
      input 'books["Gravity\'s Rainbow"]', result: :splendid
      input 'books.keys', result: ["Gravity's Rainbow", "a", "b", "c"]
      input 'ratings = Hash.new {0}', result: {}
      input 'books.values.each { |rate| ratings[rate] += 1 }',
            result: [:splendid, :mediocre, :mediocre, :mediocre]  
      input '5.times {print "Odelay!" }', result: 5, output: 'Odelay!Odelay!Odelay!Odelay!Odelay!'
      
    end
  end

  def test_lesson6
    tryruby_session do
      input 'Hash.new', result: {}
      input 'class BlogEntry', line_continuation: 1
    end
  end
  
  

  


    
end

class TryRubyOutputTest < Test::Unit::TestCase
  def test_simple_result
    t = TryRubyOutput.standard(result: [12,24])
    assert_equal("=> \033[1;20m[12, 24]", t.format_output)
  end
  
  def test_result_and_output
    t = TryRubyOutput.standard(result: 333, output: "hello")
    assert_equal("hello\n=> \033[1;20m333", t.format_output)
  end

  def test_error
    begin
      40.reverse
    rescue Exception => e
      t = TryRubyOutput.error(error: e)
    end
    assert_equal("\033[1;33mNoMethodError: undefined method `reverse' for 40:Fixnum",
                 t.format_output)
  end

  def test_line_continuation
    t = TryRubyOutput.line_continuation(3)
    assert_equal(".." * 3, t.format_output)
  end

end
    

Test::Unit::UI::Console::TestRunner.run(TryRubyOutputTest)
Test::Unit::UI::Console::TestRunner.run(TryRubyTest)
