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

use junit_report::{ReportBuilder, TestSuite};
use std::fs::File;

pub struct ReportHandler {
    report_builder: ReportBuilder,
    file_name: &'static str,
}

impl ReportHandler {
    pub fn new(file_name: &'static str) -> Self {
        Self {
            report_builder: ReportBuilder::new(),
            file_name,
        }
    }

    pub fn add_test_suite(&mut self, ts: TestSuite) {
        self.report_builder.add_testsuite(ts);
    }

    pub fn build_report(&self) {
        let r = self.report_builder.build();
        let mut file = File::create(&self.file_name).unwrap();
        r.write_xml(&mut file).unwrap();
    }
}
