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
use std::path::Path;

pub struct RaucTestCheckSysConf {
    pub test_name: &'static str,
}

impl RaucTestCheckSysConf {
    fn is_system_conf_available(&self) -> bool {
        let sys_conf_path = Path::new("/etc/rauc/system.conf");
        sys_conf_path.exists()
    }
}

#[async_trait]
impl TestParser for RaucTestCheckSysConf {
    async fn run_test(&self) -> TestCase {
        let start = SystemTime::now();

        let result = self.is_system_conf_available();

        let finished: i64 = start.elapsed().unwrap().as_millis() as i64;

        test_utils::test_result(self, 
            self.test_name,
            result,
            "/etc/rauc/system.conf is missing",
            finished,
        )

    }
}
