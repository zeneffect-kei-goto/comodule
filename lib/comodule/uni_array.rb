module Comodule
  # .<<()で追加されるメンバが重複する場合は無視するArrayのサブクラス。
  class UniArray < Array
    attr_accessor :max_size

    def <<(arg)
      if member?(arg)
        return self
      end

      super

      # max_sizeに到達したら、先頭を切り詰めて返す。
      if max_size && size > max_size
        replace self[-max_size..-1]
      end

      self
    end
  end
end
