use crate::test_parser::TestParser;
use junit_report::TestCase;
use std::process::Command;
use std::thread::park_timeout;
use std::time::{Duration, Instant}; 

pub fn is_active_system_service(service_name: &str) -> bool {
    let status = Command::new("systemctl")
        .arg("is-active")
        .arg(service_name)
        .status()
        .unwrap_or_else(|_| panic!("'systemctl is-active {}' failed!", service_name));
    println!(
        "[TestUtils] is_active_system_service '{}'. Received status: {}",
        service_name, status
    );
    println!("[TestUtils] Is execution successful: {}", status.success());
    status.success()
}

pub fn test_result(
    test_parser: &dyn TestParser,
    test_name: &'static str,
    result: bool,
    failure_msg: &'static str,
    duration: i64,
) -> TestCase {
    if result {
        test_parser.success(test_name, duration)
    } else {
        test_parser.failure(test_name, duration, failure_msg, "")
    }
}

pub fn execute_with_delay(f: fn() -> bool, period: Duration, overall_duration: Duration) -> bool {
    let beginning_park = Instant::now();
    #[allow(unused_assignments)]
    let mut timeout_remaining = overall_duration;
    #[allow(unused_assignments)]
    let mut outcome: bool = false;
    loop {
        println!("[TestUtils] park for: {}", period.as_secs());
        park_timeout(period);
        let elapsed = beginning_park.elapsed();

        timeout_remaining = if elapsed < overall_duration {
            overall_duration - elapsed
        } else {
            Duration::from_secs(0)
        };
        println!(
            "[TestUtils] timeout_remaining: {}",
            timeout_remaining.as_secs()
        );
        outcome = f();

        if timeout_remaining.is_zero() || outcome {
            break;
        }
    }
    outcome
}

