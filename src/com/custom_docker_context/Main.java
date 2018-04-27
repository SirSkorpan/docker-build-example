package com.custom_docker_context;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

public class Main {
    public static void main(String[] args) {
        try(BufferedReader greetingsReader = new BufferedReader( new FileReader("resources/greetings.text"))) {
            String greeting;
            while ((greeting = greetingsReader.readLine()) != null) {
                System.out.println(greeting);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
