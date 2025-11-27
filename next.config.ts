import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  basePath: '/habit',

  async redirects() {
    return [
      {
        source: '/',
        destination: '/habit',
        basePath: false,
        permanent: false,
      },
    ];
  },
};

export default nextConfig;