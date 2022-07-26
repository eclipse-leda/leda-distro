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
use reqwest::{ClientBuilder, Error, Response};

use crate::test_parser::TestParser;
use crate::test_utils;

pub struct AsyncWeb {
    pub test_name: &'static str,
}

impl AsyncWeb {
    async fn check_remote_status_code(&self) -> Result<Response, Error> {
        let request_url = "https://eclipse.org/".to_string();

        let timeout = std::time::Duration::new(5, 0);
        let client = ClientBuilder::new().timeout(timeout).build().unwrap();
        let response = client.head(&request_url).send().await;

        response
    }
}

#[async_trait]
impl TestParser for AsyncWeb {
    async fn run_test(&self) -> TestCase {
        let start = std::time::SystemTime::now();
        let status = self.check_remote_status_code().await;
        let finished = start.elapsed().unwrap().as_millis() as i64;

        test_utils::test_result(
            self,
            self.test_name,
            status.is_ok(),
            "Unable to fetch content",
            finished,
        )
    }
}
