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

pub struct SSHdTest {
    pub test_name: &'static str,
}

impl SSHdTest {
    fn get_sshd_pid(&self) -> usize {
        let mut sys = System::default();
        sys.refresh_all();
        sys.processes_by_exact_name("sshd").count()
    }
}

#[async_trait]
impl TestParser for SSHdTest {
    async fn run_test(&self) -> TestCase {
        let start = SystemTime::now();
        let sshd_ps = self.get_sshd_pid();
        let finished: i64 = start.elapsed().unwrap().as_millis() as i64;

        test_utils::test_result(
            self,
            self.test_name,
            sshd_ps > 0,
            "Unable to get SSHD_Pid",
            finished,
        )
    }
}
