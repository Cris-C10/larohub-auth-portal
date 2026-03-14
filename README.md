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

## Authentication Flow

## Infrastructure Components

## Security Model

## Terraform Deployment

## Repository Structure

## Relation to LAROHUB Ingestion Backbone
