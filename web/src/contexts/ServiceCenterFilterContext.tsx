import { createContext, useContext } from 'react';

interface ServiceCenterFilterContextValue {
  selectedServiceCenter: string | null;
}

export const ServiceCenterFilterContext = createContext<ServiceCenterFilterContextValue>({
  selectedServiceCenter: null,
});

export function useServiceCenterFilter() {
  return useContext(ServiceCenterFilterContext);
}
