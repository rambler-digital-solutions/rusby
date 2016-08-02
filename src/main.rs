extern crate rand;

use std::io::{self, Write};
use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use rand::distributions::{IndependentSample, Range};

// this function folds ffi arguments and unfolds result to ffi types
#[no_mangle]
pub extern "C" fn ffi_pick(weights_pointer: *mut i32, weights_size: usize) -> i32 {
    let weights = unsafe { std::slice::from_raw_parts_mut(weights_pointer, weights_size) };
    let result = pick(weights);
    return result;
}

#[allow(unused_mut)]
fn pick(weights: &mut [i32]) -> i32 {
    let mut sum = 0;
    // let mut weightsL = Vec::new();
    // let mut weightsR = Vec::new();
    // for weight in &weights {
    // }
    // let mut sample = Range::new(0.0, 1.0).ind_sample(rand::thread_rng()) * sum;
    for (i, weight) in weights.iter().enumerate() {
    }
    return -1 as i32;
}
