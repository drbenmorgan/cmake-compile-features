#include "ccf.hpp"
#include <iostream>
#include <sstream>
#include <thread>
#include <vector>
#include "ccf_compiler_detection.hpp"

namespace ccf {

/// check that a TLS variable can be defined using the generated macro
/// that should expand to the appropriate keyword for this.
CCF_THREAD_LOCAL int myTLS(0);


void increaseValue(const std::string& id, int increment, int& res) {
  ccf::myTLS += increment;
  res = ccf::myTLS;
}


void dispatchThreads() {
  std::vector<int> results = {0,0,0,0,0};
  std::thread t1(increaseValue,"one",52, std::ref(results[0]));
  std::thread t2(increaseValue,"two",4, std::ref(results[1]));
  std::thread t3(increaseValue,"three",821, std::ref(results[2]));
  std::thread t4(increaseValue,"four",7, std::ref(results[3]));
  std::thread t5(increaseValue,"five",0, std::ref(results[4]));

  t5.join();
  t4.join();
  t3.join();
  t2.join();
  t1.join();

  for(auto r : results) {
    std::cout << "thatTLS = " << r << std::endl;
  }
}


void message(const std::string& m) {
  std::cout << m << std::endl;
  dispatchThreads();
  std::cout << "dispatching complete" << std::endl;
}



} // namespace ccf

