# Copyright 2014 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

gem "minitest"
require "minitest/autorun"
require "ostruct"
require "json"
require "gcloud/storage"
require "gcloud/pubsub"

class MockStorage < Minitest::Spec
  let(:project) { "test" }
  let(:credentials) { OpenStruct.new }
  let(:storage) { Gcloud::Storage::Project.new project, credentials }

  def setup
    @connection = Faraday::Adapter::Test::Stubs.new
    connection = storage.instance_variable_get "@connection"
    client = connection.instance_variable_get "@client"
    client.connection = Faraday.new do |builder|
      # builder.options.params_encoder = Faraday::FlatParamsEncoder
      builder.adapter :test, @connection
    end
  end

  def teardown
    @connection.verify_stubbed_calls
  end

  def mock_connection
    @connection
  end


  def random_bucket_hash name=random_bucket_name
    {"kind"=>"storage#bucket",
        "id"=>name,
        "selfLink"=>"https://www.googleapis.com/storage/v1/b/#{name}",
        "projectNumber"=>"1234567890",
        "name"=>name,
        "timeCreated"=>Time.now,
        "metageneration"=>"1",
        "owner"=>{"entity"=>"project-owners-1234567890"},
        "location"=>"US",
        "storageClass"=>"STANDARD",
        "etag"=>"CAE="}
  end

  def random_file_hash bucket=random_bucket_name, name=random_file_path
    {"kind"=>"storage#object",
     "id"=>"#{bucket}/#{name}/1234567890",
     "selfLink"=>"https://www.googleapis.com/storage/v1/b/#{bucket}/o/#{name}",
     "name"=>"#{name}",
     "bucket"=>"#{bucket}",
     "generation"=>"1234567890",
     "metageneration"=>"1",
     "contentType"=>"text/plain",
     "updated"=>Time.now,
     "storageClass"=>"STANDARD",
     "size"=>rand(10_000),
     "md5Hash"=>"HXB937GQDFxDFqUGi//weQ==",
     "mediaLink"=>"https://www.googleapis.com/download/storage/v1/b/#{bucket}/o/#{name}?generation=1234567890&alt=media",
     "owner"=>{"entity"=>"user-1234567890", "entityId"=>"abc123"},
     "crc32c"=>"Lm1F3g==",
     "etag"=>"CKih16GjycICEAE="}
  end

  def random_bucket_name
    (0...50).map { ("a".."z").to_a[rand(26)] }.join
  end

  def random_file_path
    [(0...10).map { ("a".."z").to_a[rand(26)] }.join,
     (0...10).map { ("a".."z").to_a[rand(26)] }.join,
     (0...10).map { ("a".."z").to_a[rand(26)] }.join + ".txt"].join "/"
  end

  # Register this spec type for when :storage is used.
  register_spec_type(self) do |desc, *addl|
    addl.include? :mock_storage
  end
end

class MockPubsub < Minitest::Spec
  let(:project) { "test" }
  let(:credentials) { OpenStruct.new }
  let(:pubsub) { Gcloud::Pubsub::Project.new project, credentials }

  def setup
    @connection = Faraday::Adapter::Test::Stubs.new
    connection = pubsub.instance_variable_get "@connection"
    client = connection.instance_variable_get "@client"
    client.connection = Faraday.new do |builder|
      # builder.options.params_encoder = Faraday::FlatParamsEncoder
      builder.adapter :test, @connection
    end
  end

  def teardown
    @connection.verify_stubbed_calls
  end

  def mock_connection
    @connection
  end

  def topics_json num_topics, token = nil
    topics = num_topics.times.map do
      JSON.parse(topic_json("topic-#{rand 1000}"))
    end
    data = { "topics" => topics }
    data["nextPageToken"] = token unless token.nil?
    data.to_json
  end

  def topic_json topic_name
    { "name" => topic_path(topic_name) }.to_json
  end

  def subscriptions_json topic_name, num_subs, token = nil
    subs = num_subs.times.map do
      JSON.parse(subscription_json(topic_name, "sub-#{rand 1000}"))
    end
    data = { "subscriptions" => subs }
    data["nextPageToken"] = token unless token.nil?
    data.to_json
  end

  def subscription_json topic_name, sub_name,
                        deadline = 60,
                        endpoint = "http://example.com/callback"
    { "name" => subscription_path(sub_name),
      "topic" => topic_path(topic_name),
      "pushConfig" => { "pushEndpoint" => endpoint },
      "ackDeadlineSeconds" => deadline,
    }.to_json
  end

  def event_json message
    {
      "ackId" => "ack-id-123456789",
      "message" => {
        "data" => [message].pack("m"),
        "attributes" => {},
        "messageId" => "msg-id-123456789",
      }
    }.to_json
  end

  def events_json message
    {
      "receivedMessages" => [
        JSON.parse(event_json(message))
      ]
    }.to_json
  end

  def already_exists_error_json resource_name
    {
      "error" => {
        "code" => 409,
        "message" => "Resource already exists in the project (resource=#{resource_name}).",
        "errors" => [
          {
            "message" => "Resource already exists in the project (resource=#{resource_name}).",
            "domain" => "global",
            "reason" => "alreadyExists"
          }
        ],
        "status" => "ALREADY_EXISTS"
      }
    }.to_json
  end

  def not_found_error_json resource_name
    {
      "error" => {
        "code" => 404,
        "message" => "Resource not found (resource=foo2).",
        "errors" => [
          {
            "message" => "Resource not found (resource=foo2).",
            "domain" => "global",
            "reason" => "notFound"
          }
        ],
        "status" => "NOT_FOUND"
      }
    }.to_json
  end

  def project_path
    "projects/#{project}"
  end

  def topic_path topic_name
    "#{project_path}/topics/#{topic_name}"
  end

  def subscription_path subscription_name
    "#{project_path}/subscriptions/#{subscription_name}"
  end

  # Register this spec type for when :storage is used.
  register_spec_type(self) do |desc, *addl|
    addl.include? :mock_pubsub
  end
end
