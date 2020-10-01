# frozen_string_literal: true

# Provide String.to_base64 as refinement
module Base64Helper
  refine String do
    def to_base64
      [self].pack('m*').chomp
    end

    def from_base64
      unpack1('m*')
    end
  end
end
