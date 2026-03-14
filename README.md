# LAROHUB Auth Portal

## Architecture Overview

The LAROHUB Auth Portal provides authentication and session validation for the LARO Hub platform.

Authentication is handled through Amazon Cognito Hosted UI using the OAuth2 Authorization Code flow.

User traffic enters through a CloudFront distribution that serves both the static frontend and authentication endpoints.

Authentication endpoints are routed to an API Gateway HTTP API which invokes Lambda functions responsible for:

- OAuth callback processing
- JWT session validation
- User logout

Sessions are stored as Secure HttpOnly cookies containing the Cognito ID token. The frontend validates authentication state by calling the `/portal/me` endpoint.

Infrastructure is managed entirely through Terraform.

## Authentication Flow

1. User clicks **Login** on the frontend.

2. Browser is redirected to the Amazon Cognito Hosted UI.

3. After successful authentication, Cognito redirects the browser to:
/portal/callback

4. The `/portal/callback` Lambda exchanges the authorization code for Cognito tokens.

5. The Lambda sets a Secure HttpOnly cookie:
larohub_id_token

6. The user is redirected to `/dashboard.html`.

7. The frontend calls:
/portal/me

to validate the session.

8. The `/portal/me` Lambda validates the JWT against the Cognito JWKS endpoint and returns the authenticated user information.

## Infrastructure Components

The authentication portal is composed of the following AWS components.

### CloudFront

Single public entry point for the system.

Responsibilities:

- Serve static frontend from S3
- Route authentication endpoints
- Enforce HTTPS

### Amazon S3

Stores static frontend assets:

- dashboard.html
- scripts.js

The bucket is private and accessible only via CloudFront Origin Access Control (OAC).

### API Gateway (HTTP API)

Handles authentication-related endpoints:
/portal/callback
/portal/me
/portal/logout


### AWS Lambda

Implements authentication logic.

Functions:

- portal-callback
- portal-me
- portal-logout

### Amazon Cognito

Provides identity management and OAuth2 login.

Features used:

- Hosted UI
- Authorization Code flow
- User groups
- JWT token issuance
  
## Security Model

Authentication uses the OAuth2 Authorization Code flow via Amazon Cognito.

Security principles implemented:

### Secure Cookie Sessions

User sessions are stored in a Secure HttpOnly cookie:
larohub_id_token

The cookie cannot be accessed by client-side JavaScript.

### JWT Validation

The `/portal/me` Lambda verifies the JWT signature using Cognito's JWKS endpoint.

### Private S3 Access

The S3 bucket hosting frontend assets is private and accessible only through CloudFront Origin Access Control.

### No Public Backend Endpoints

All authentication routes are exposed only through the CloudFront distribution.

### Authorization via Cognito Groups

User authorization is determined through:
cognito:groups

Claims contained within the ID token.

## Terraform Deployment

Infrastructure is provisioned using Terraform.

Terraform modules manage:

- CloudFront distribution
- API Gateway HTTP API
- Lambda functions
- IAM roles
- Cognito user pool
- Cognito app client
- Cognito hosted domain

Terraform state is currently stored locally during the development phase.

The repository excludes state files via `.gitignore` to prevent accidental publication of infrastructure state.

## Repository Structure

```
larohub-auth-portal/
├─ main.tf
├─ auth_api.tf
├─ auth_lambda.tf
├─ cognito.tf
├─ cognito_client.tf
├─ cognito_domain.tf
├─ cloudfront_callback_routing.tf
├─ outputs.tf
├─ lambda/
│  ├─ callback.py
│  ├─ me.py
│  ├─ logout.py
└─ README.md
```

Terraform configuration files define the infrastructure, while the `lambda/` directory contains the authentication Lambda functions.

## Relation to LAROHUB Ingestion Backbone

This repository implements the authentication layer for the LARO Hub platform.

It operates alongside the **LAROHUB Ingestion Backbone**:

https://github.com/Cris-C10/larohub-ingestion-backbone

Responsibilities of this repository:

- User authentication
- Session management
- Authorization group validation
- Secure frontend access

The ingestion backbone repository manages the data pipeline infrastructure and backend processing components.
