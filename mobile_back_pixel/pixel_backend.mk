# Copyright 2021 The MLPerf Authors. All Rights Reserved.
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
##########################################################################

ifeq (${WITH_PIXEL},1)
  $(info WITH_PIXEL=1)
  android_pixel_backend_bazel_flag=--//android/java/org/mlperf/inference:with_pixel="1"
  backend_pixel_android_files=${BAZEL_LINKS_PREFIX}bin/mobile_back_pixel/cpp/backend_tflite/libtflitepixelbackend.so
  backend_pixel_android_target=//mobile_back_pixel/cpp/backend_tflite:libtflitepixelbackend.so
  backend_pixel_filename=libtflitepixelbackend
endif
