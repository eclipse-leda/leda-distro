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
use std::time::SystemTime;

use crate::test_parser::TestParser;
use crate::test_utils;

pub struct RaucTestCheckRaucMarkGoodService {
    pub test_name: &'static str,
}

#[async_trait]
impl TestParser for RaucTestCheckRaucMarkGoodService {
    async fn run_test(&self) -> TestCase {
        let start = SystemTime::now();

        let result = test_utils::is_active_system_service("rauc-mark-good");

        let finished: i64 = start.elapsed().unwrap().as_millis() as i64;

        test_utils::test_result(self, 
            self.test_name,
            result,
            "'rauc-mark-good' service is not active!",
            finished,
        )

    }
}
