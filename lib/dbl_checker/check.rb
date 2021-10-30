require 'ostruct'
require 'securerandom'
require 'json'

#
# == Schema Information
#
# id                                 :uuid      not null
# created_at                         :datetime  not null
# updated_at                         :datetime  not null
# finished_at                        :datetime  not null
# error                              :text
# app_version(e.g. the commit hash)  :string    not null
# timout_after_seconds               :integer
# execution_time_in_ms               :integer
# name                               :string    not null
# description                        :string
# job_klass                          :string    not null
# runbook                            :string
#

module DBLChecker
  class Check < OpenStruct
    def to_json(*_args)
      to_h.to_json
    end

    # the remote system will have its own unique id (from the DB)
    # but we want to be able to send a UUID to Slack
    # so we can link to the remote system from Slack (e.g. a link to a dashboard)
    def id
      @id ||= SecureRandom.uuid
    end
  end
end
