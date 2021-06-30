#pragma once
#include <iostream>
#include <fstream>
#include <string>

class Tracer {
public:
	Tracer() = default;
	~Tracer() { close(); }

	bool open(const std::string& filename) {
		return false;
	}

	void dump(size_t cnt) {
	}
	void flush() {
	}
	void close() {
	}

};
