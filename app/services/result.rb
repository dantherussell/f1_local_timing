# frozen_string_literal: true

class Result
  attr_reader :data, :errors

  def initialize(success:, data: nil, errors: [])
    @success = success
    @data = data
    @errors = Array(errors)
  end

  def success?
    @success
  end

  def failure?
    !success?
  end

  def self.success(data = nil)
    new(success: true, data: data)
  end

  def self.failure(errors)
    new(success: false, errors: errors)
  end
end
