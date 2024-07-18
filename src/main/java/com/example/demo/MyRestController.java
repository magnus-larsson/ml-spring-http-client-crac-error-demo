package com.example.demo;

import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
@RequestMapping("/")
public class MyRestController {
    
	private final RestTemplate restTemplate;

	public MyRestController(RestTemplateBuilder restTemplateBuilder) {
		this.restTemplate = restTemplateBuilder.build();
	}

	@GetMapping("/usingRestTemplate")
	String requestUsingRestTemplate() {
		return restTemplate.getForObject("https://httpbin.org/uuid", String.class);
	}
}
