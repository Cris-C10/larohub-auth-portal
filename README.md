# LAROHUB Auth Portal

The LAROHUB Auth Portal provides authentication and session validation for the LARO Hub platform.

Authentication is handled through Amazon Cognito Hosted UI using the OAuth2 Authorization Code flow.

User traffic enters through a CloudFront distribution that serves both the static frontend and authentication endpoints.

Authentication endpoints are routed to an API Gateway HTTP API which invokes Lambda functions responsible for:

- OAuth callback processing
- JWT session validation
- User logout

Sessions are stored as Secure HttpOnly cookies containing the Cognito ID token. The frontend validates authentication state by calling the `/portal/me` endpoint.

Infrastructure is managed entirely through Terraform.

## Architecture Overview

## Authentication Flow

## Infrastructure Components

## Security Model

## Terraform Deployment

## Repository Structure

## Relation to LAROHUB Ingestion Backbone
