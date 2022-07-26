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

use async_trait::async_trait;
use junit_report::TestCase;
use serde_json::Value;
use std::time::{Duration, SystemTime};

use crate::test_parser::TestParser;
use crate::test_utils;

pub struct K3STests {
    pub test_name: &'static str,
    pub config: Value,
}

impl K3STests {
    fn is_k3s_active() -> bool {
        test_utils::is_active_system_service("k3s")
    }

    fn is_k3s_active_with_delay(&self, period: Duration, overall_duration: Duration) -> bool {
        test_utils::execute_with_delay(K3STests::is_k3s_active, period, overall_duration)
    }
}

#[async_trait]
impl TestParser for K3STests {
    async fn run_test(&self) -> TestCase {
        let start = SystemTime::now();

        let k3s_test_config = self.config.get("k3s-test-config");

        let overall_duration = k3s_test_config
            .and_then(|value| value.get("overall-delay-sec"))
            .and_then(|value| value.as_u64())
            .unwrap();

        let period = k3s_test_config
            .and_then(|value| value.get("check-period-sec"))
            .and_then(|value| value.as_u64())
            .unwrap();

        let is_active = self.is_k3s_active_with_delay(
            Duration::from_secs(period),
            Duration::from_secs(overall_duration),
        );
        let finished: i64 = start.elapsed().unwrap().as_millis() as i64;

        test_utils::test_result(
            self,
            self.test_name,
            is_active,
            "k3s service is not active",
            finished,
        )
    }
}
