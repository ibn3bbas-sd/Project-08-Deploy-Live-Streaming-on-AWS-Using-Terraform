// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { render, screen } from '@testing-library/react';
import App from './App';

// Mock the aws-exports file
jest.mock('./aws-exports', () => ({
  hls_manifest: 'https://example.com/hls.m3u8',
  dash_manifest: 'https://example.com/dash.mpd',
  cmaf_manifest: 'https://example.com/cmaf.m3u8',
  mediaLiveConsole: 'https://console.aws.amazon.com/medialive',
}), { virtual: true });


test('renders learn react link', () => {
  render(<App />);
  const linkElement = screen.getByText(/Live Streaming on AWS/i);
  expect(linkElement).toBeInTheDocument();
});
