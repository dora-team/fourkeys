# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from setuptools import setup

setup(
   name='shared',
   version='1.0',
   description='Shared functions for the Four Keys pipeline',
   url='git@github.com:four-keys-playground.git#egg=shared&subdirectory=shared',
   author='Google Inc.',
   license='Apache-2.0',
   py_modules=['shared'],
   install_requires=['google-cloud-bigquery'],
   zip_safe=False
)
