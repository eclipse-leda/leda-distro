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
use std::process::Command;
use std::time::SystemTime;

use crate::test_parser::TestParser;
use crate::test_utils;
use serde_json::Value;

pub struct RaucTestSlotStatus {
    pub test_name: &'static str,
}

impl RaucTestSlotStatus {
    fn are_slots_good(&self) -> bool {
        let output = Command::new("rauc")
            .arg("status")
            .arg("--output-format=json")
            .output()
            .expect("failed to execute process");
        let output = String::from_utf8_lossy(&output.stdout);
        //for test purposes for different outputs
        //let output = read_to_string("src/rauc-status.json").unwrap();
        println!(
            "[RaucTestSlotStatus] Output from rauc status cmd: {} ",
            output
        );
        let v: Value = serde_json::from_str(&output).unwrap();
        let slots = v.get("slots");
        for slot in slots.unwrap().as_array().unwrap() {
            let root_fs = &slot.as_object();
            let map = root_fs.unwrap();
            let partitions = map.keys();
            for partition_key in partitions {
                let partition_value = map.get(partition_key).unwrap();
                let class = &partition_value.get("class").unwrap().as_str();
                if "rootfs".eq(class.unwrap()) {
                    let state = partition_value.get("state").unwrap().as_str();
                    let boot_status_str = partition_value.get("boot_status").unwrap().as_str();
                    if "booted".eq(state.unwrap()) && "good".eq(boot_status_str.unwrap()) {
                        return true;
                    }
                }
            }
        }
        false
    }
}

#[async_trait]
impl TestParser for RaucTestSlotStatus {
    async fn run_test(&self) -> TestCase {
        let start = SystemTime::now();

        let result = self.are_slots_good();

        let finished: i64 = start.elapsed().unwrap().as_millis() as i64;

        test_utils::test_result(
            self,
            self.test_name,
            result,
            "Root fs slots are not marked as good",
            finished,
        )
    }
}
