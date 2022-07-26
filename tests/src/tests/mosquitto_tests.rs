//
// Copyright (c) 2022 Contributors to the Eclipse Foundation
//
// See the NOTICE file(s) distributed with this work for additional
// information regarding copyright ownership.
//
// This program and the accompanying materials are made available under the
// terms of the Apache License 2.0 which is available at
// https://www.apache.org/licenses/LICENSE-2.0
//
// SPDX-License-Identifier: Apache-2.0
//

use crate::test_parser::TestParser;
use async_trait::async_trait;
use junit_report::TestCase;
use serde_json::Value;
use std::process::Command;
use std::process::Stdio;
use std::time::{Duration, SystemTime};
use crate::test_utils;

pub struct MosquittoTests {
    pub test_name: &'static str,
    pub config: Value,
}

impl MosquittoTests {

    fn is_mosquitto_active() -> bool {
        let output = Command::new("/usr/local/bin/kubectl")
            .arg("get")
            .arg("service")
            .arg("mosquitto")
            .arg("-o")
            .arg("jsonpath='{.spec.ports[?(@.port==1883)].nodePort}'")
            .stdout(Stdio::piped())
            .output()
            .expect("Service mosquitto could not be found.");

        // extract the raw bytes that we captured and interpret them as a string
        let stdout = String::from_utf8(output.stdout).unwrap();
        "'31883'".eq(&*stdout)
    }

    fn is_mosquitto_active_with_delay(&self, period: Duration, overall_duration: Duration) -> bool {
        test_utils::execute_with_delay(MosquittoTests::is_mosquitto_active, period, overall_duration)
    }    
}

#[async_trait]
impl TestParser for MosquittoTests {
    async fn run_test(&self) -> TestCase {
        let start = SystemTime::now();
        let mosquitto_test_config = self.config.get("mosquitto-test-config");

        let overall_duration = mosquitto_test_config
            .and_then(|value| value.get("overall-delay-sec"))
            .and_then(|value| value.as_u64())
            .unwrap();

        let period = mosquitto_test_config
            .and_then(|value| value.get("check-period-sec"))
            .and_then(|value| value.as_u64())
            .unwrap();

        let result: bool = self.is_mosquitto_active_with_delay(
            Duration::from_secs(period),
            Duration::from_secs(overall_duration),
        );
        let finished: i64 = start.elapsed().unwrap().as_millis() as i64;

        if result {
            self.success(self.test_name, finished)
        } else {
            self.failure(
                self.test_name,
                finished,
                "Service mosquitto could not be found.",
                "",
            )
        }
    }
}
