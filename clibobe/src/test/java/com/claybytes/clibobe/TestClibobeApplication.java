package com.claybytes.clibobe;

import org.springframework.boot.SpringApplication;

public class TestClibobeApplication {

	public static void main(String[] args) {
		SpringApplication.from(ClibobeApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
