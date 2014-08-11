require 'spec_helper'
require 'armada/logging'

class TestLogging
  extend Armada::Logging
  def self.logger
    log
  end
end

describe Armada::Logging do
  let(:message) { %w{ something something_else } }

  context '#info' do
    it 'passes through to Logger' do
      expect(TestLogging.logger).to receive(:info).with(message.join(' '))
      TestLogging.info(*message)
    end
  end

  context '#warn' do
    it 'passes through to Logger' do
      expect(TestLogging.logger).to receive(:warn).with(message.join(' '))
      TestLogging.warn(*message)
    end
  end

  context '#debug' do
    it 'passes through to Logger' do
      expect(TestLogging.logger).to receive(:debug).with(message.join(' '))
      TestLogging.debug(*message)
    end
  end

  context '#error' do
    it 'passes through to Logger' do
      expect(TestLogging.logger).to receive(:error).with(message.join(' '))
      TestLogging.error(*message)
    end
  end
end
