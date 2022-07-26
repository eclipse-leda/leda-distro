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
use sysinfo::{System, SystemExt};

use crate::test_parser::TestParser;
use crate::test_utils;

pub struct OSTests {
    pub test_name: &'static str,
}

impl OSTests {
    fn get_boot_time(&self) -> u64 {
        let mut sys = System::new_all();
        sys.refresh_all();
        sys.boot_time()
    }
}

#[async_trait]
impl TestParser for OSTests {
    async fn run_test(&self) -> TestCase {
        let start = SystemTime::now();
        let boot_time = self.get_boot_time();
        let finished: i64 = start.elapsed().unwrap().as_millis() as i64;

        test_utils::test_result(
            self,
            self.test_name,
            boot_time > 0,
            "unable to get boot time",
            finished,
        )
    }
}
