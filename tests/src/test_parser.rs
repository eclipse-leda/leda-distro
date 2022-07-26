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
use junit_report::{
    Duration, OffsetDateTime, TestCase, TestCaseBuilder, TestSuite, TestSuiteBuilder,
};

#[async_trait]
pub trait TestParser {
    async fn run_test(&self) -> TestCase;

    fn success(&self, test_name: &'static str, finished: i64) -> TestCase {
        println!(
            "[TestResult] Test: {}... Success ({:?} millis.)",
            test_name, finished
        );
        TestCaseBuilder::success(test_name, Duration::milliseconds(finished)).build()
    }

    fn failure(
        &self,
        test_name: &'static str,
        finished: i64,
        message: &'static str,
        type_: &'static str,
    ) -> TestCase {
        println!(
            "[TestResult] Test: {}... Failure ({:?} millis.)",
            test_name, finished
        );
        TestCaseBuilder::failure(test_name, Duration::milliseconds(finished), type_, message)
            .build()
    }
}

// to do: Work on multithreading support here
pub async fn test_suite_builder(tp: Vec<&dyn TestParser>) -> TestSuite {
    let mut test_suite = TestSuiteBuilder::new("Eclipse Leda Smoketests");

    for test_parser in tp {
        test_suite.add_testcase(test_parser.run_test().await);
    }

    test_suite.set_timestamp(OffsetDateTime::now_utc()).build()
}
