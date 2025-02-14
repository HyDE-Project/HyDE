import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import SideLeft from '../main';

describe('SideLeft component', () => {
  it('renders without crashing', () => {
    render(<SideLeft />);
    expect(screen.getByTestId('side-left')).toBeInTheDocument();
  });

  it('displays the correct title', () => {
    render(<SideLeft />);
    expect(screen.getByText('Side Left')).toBeInTheDocument();
  });

  it('contains the expected child components', () => {
    render(<SideLeft />);
    expect(screen.getByTestId('side-left-content')).toBeInTheDocument();
    expect(screen.getByTestId('side-left-footer')).toBeInTheDocument();
  });

  it('applies the correct CSS classes', () => {
    render(<SideLeft />);
    const sideLeft = screen.getByTestId('side-left');
    expect(sideLeft).toHaveClass('side-left');
    expect(sideLeft).toHaveClass('bg-gray-100');
    expect(sideLeft).toHaveClass('dark:bg-gray-800');
  });

  it('has the correct structure', () => {
    render(<SideLeft />);
    const sideLeft = screen.getByTestId('side-left');
    expect(sideLeft.tagName).toBe('DIV');
    expect(sideLeft.children.length).toBe(3);
    expect(sideLeft.children[0].tagName).toBe('H2');
    expect(sideLeft.children[1].tagName).toBe('DIV');
    expect(sideLeft.children[2].tagName).toBe('DIV');
  });
});
