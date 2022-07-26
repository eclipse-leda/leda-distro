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

mod report_handler;
mod test_parser;
mod tests;

mod test_utils;

use report_handler::ReportHandler;
use test_parser::{test_suite_builder, TestParser};
use tests::{
    async_web_tests::AsyncWeb, k3s_tests::K3STests, mosquitto_tests::MosquittoTests,
    os_tests::OSTests, rauc_tests_check_rauc_mark_good_service::RaucTestCheckRaucMarkGoodService,
    rauc_tests_check_rauc_service::RaucTestCheckRaucService,
    rauc_tests_slot_status::RaucTestSlotStatus, rauc_tests_sys_conf::RaucTestCheckSysConf,
    sshd_tests::SSHdTest,
};

#[tokio::main]
async fn main() {
    let mut report_handler = ReportHandler::new("junit-results.xml");
    let config_str = include_str!("config.json");
    let json_config_k3s: serde_json::Value = serde_json::from_str(config_str).unwrap();
    let json_config_msq: serde_json::Value = json_config_k3s.clone();

    let k3s_tests = K3STests {
        test_name: "K3S Test",
        config: json_config_k3s,
    };

    let mosquitto_tests: MosquittoTests = MosquittoTests {
        test_name: "Mosquitto Test",
        config: json_config_msq,
    };

    // Please add custom tests below
    let tests: Vec<&dyn TestParser> = vec![
        &OSTests {
            test_name: "Boot Time Test",
        },
        &SSHdTest {
            test_name: "SSHD Test",
        },
        &k3s_tests,
        &RaucTestCheckSysConf {
            test_name: "Rauc System.conf Test",
        },
        &RaucTestCheckRaucService {
            test_name: "Is Rauc Service Active",
        },
        &RaucTestCheckRaucMarkGoodService {
            test_name: "Is Rauc Mark Good Service Active",
        },
        &RaucTestSlotStatus {
            test_name: "Rauc Slot Status Check",
        },
        &AsyncWeb {
            test_name: "Asynchronous HTTP Call",
        },
        &mosquitto_tests,
    ];

    report_handler.add_test_suite(test_suite_builder(tests).await);
    report_handler.build_report();
}
