#--
# Copyright 2015 Google Inc. All rights reserved.
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

require "gcloud/credentials"

module Gcloud
  module Pubsub
    ##
    # Represents the Oauth2 signing logic for Pubsub.
    class Credentials < Gcloud::Credentials #:nodoc:
      SCOPE = ["https://www.googleapis.com/auth/pubsub",
               "https://www.googleapis.com/auth/cloud-platform"]
      PATH_ENV_VARS = %w(PUBSUB_KEYFILE GOOGLE_CLOUD_KEYFILE)
      JSON_ENV_VARS = %w(PUBSUB_KEYFILE_JSON GOOGLE_CLOUD_KEYFILE_JSON)
    end
  end
end
