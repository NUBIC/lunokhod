require 'lunokhod'

module NodeExtraction
  include Lunokhod::Visitation

  def condition_for(survey, qtag, ctag)
    visit(survey, true) do |n, _, _, _|
      if n.is_a?(Lunokhod::Ast::Condition) && \
        n.tag == ctag &&
        n.parent.question.tag == qtag
        break n
      end
    end
  end
end
